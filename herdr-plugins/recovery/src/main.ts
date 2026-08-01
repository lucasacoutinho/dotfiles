import { createHash } from "node:crypto";
import {
  mkdir,
  open,
  readFile,
  rename,
  stat,
  unlink,
  writeFile,
} from "node:fs/promises";
import { join } from "node:path";
import { captureTargets, mergeTargets, parseCheckpoint } from "./checkpoint";
import { loadConfig } from "./config";
import { HerdrClient } from "./herdr";
import {
  auditTargets,
  recoverTargets,
  recoverTargetsWithRetries,
} from "./recovery";
import type {
  RecoveryCheckpoint,
  RecoveryRecord,
  RecoveryReport,
  RecoveryTarget,
} from "./types";

const PLUGIN_VERSION = "0.2.0";
const command = process.argv[2];
const configDirectory = process.env.HERDR_PLUGIN_CONFIG_DIR;
const stateDirectory = process.env.HERDR_PLUGIN_STATE_DIR;

function sessionKey(): string {
  return createHash("sha256")
    .update(process.env.HERDR_SOCKET_PATH ?? "default")
    .digest("hex")
    .slice(0, 12);
}

function statePath(name: string): string {
  if (!stateDirectory) throw new Error("HERDR_PLUGIN_STATE_DIR is not set");
  return join(stateDirectory, `${name}-${sessionKey()}`);
}

function reportPath(): string {
  return `${statePath("last-report")}.json`;
}

function checkpointPath(): string {
  return `${statePath("checkpoint")}.json`;
}

function startupMarkerPath(): string {
  return `${statePath("startup")}.active`;
}

function lockPath(name: string): string {
  return `${statePath(name)}.lock`;
}

function sleep(milliseconds: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, milliseconds));
}

function formatReport(report: RecoveryReport): string {
  const lines = [
    `Herdr recovery ${PLUGIN_VERSION}`,
    `Command: ${report.command}`,
    `Healthy: ${report.healthy ? "yes" : "no"}`,
    `Checkpoint: ${report.checkpoint}`,
    `Checkpointed panes: ${report.checkpointPanes}`,
    `Eligible panes: ${report.eligiblePanes}`,
    `Repaired panes: ${report.repairedPanes}`,
  ];

  for (const record of report.records) {
    lines.push(
      `${record.paneId} ${record.agent} ${record.before} -> ${record.after} (${record.action}): ${record.message}`,
    );
  }

  return `${lines.join("\n")}\n`;
}

async function saveReport(report: RecoveryReport): Promise<void> {
  if (!stateDirectory) return;
  await mkdir(stateDirectory, { recursive: true, mode: 0o700 });
  const destination = reportPath();
  const temporary = `${destination}.${process.pid}.tmp`;
  await writeFile(temporary, `${JSON.stringify(report, null, 2)}\n`, { mode: 0o600 });
  await rename(temporary, destination);
}

async function showLastReport(): Promise<void> {
  process.stdout.write(await readFile(reportPath(), "utf8"));
}

async function readCheckpoint(): Promise<RecoveryCheckpoint | null> {
  try {
    const parsed = parseCheckpoint(JSON.parse(await readFile(checkpointPath(), "utf8")));
    if (!parsed) throw new Error("The recovery checkpoint is invalid");
    return parsed;
  } catch (error) {
    if ((error as NodeJS.ErrnoException).code === "ENOENT") return null;
    throw error;
  }
}

async function writeCheckpoint(targets: RecoveryTarget[]): Promise<void> {
  if (!stateDirectory) throw new Error("HERDR_PLUGIN_STATE_DIR is not set");
  await mkdir(stateDirectory, { recursive: true, mode: 0o700 });
  const checkpoint: RecoveryCheckpoint = {
    version: 1,
    savedAt: new Date().toISOString(),
    targets,
  };
  const destination = checkpointPath();
  const temporary = `${destination}.${process.pid}.tmp`;
  await writeFile(
    temporary,
    `${JSON.stringify(checkpoint, null, 2)}\n`,
    { mode: 0o600 },
  );
  await rename(temporary, destination);
}

async function acquireLock(name: string): Promise<() => Promise<void>> {
  if (!stateDirectory) throw new Error("HERDR_PLUGIN_STATE_DIR is not set");
  await mkdir(stateDirectory, { recursive: true, mode: 0o700 });
  const path = lockPath(name);

  for (let attempt = 0; attempt < 40; attempt += 1) {
    try {
      const handle = await open(path, "wx", 0o600);
      await handle.writeFile(`${process.pid} ${new Date().toISOString()}\n`);
      await handle.close();
      return async () => {
        try {
          await unlink(path);
        } catch (error) {
          if ((error as NodeJS.ErrnoException).code !== "ENOENT") throw error;
        }
      };
    } catch (error) {
      if ((error as NodeJS.ErrnoException).code !== "EEXIST") throw error;
      const ageMs = Date.now() - (await stat(path)).mtimeMs;
      if (ageMs > 10 * 60_000) {
        await unlink(path);
        continue;
      }
      if (attempt < 39) {
        await sleep(50);
        continue;
      }
      throw new Error(`Another ${name} command is already running for this Herdr session`);
    }
  }

  throw new Error(`Could not acquire the ${name} lock`);
}

async function markerIsActive(path: string): Promise<boolean> {
  try {
    const ageMs = Date.now() - (await stat(path)).mtimeMs;
    if (ageMs <= 10 * 60_000) return true;
    await unlink(path);
    return false;
  } catch (error) {
    if ((error as NodeJS.ErrnoException).code === "ENOENT") return false;
    throw error;
  }
}

async function recoveryIsActive(): Promise<boolean> {
  return await markerIsActive(startupMarkerPath())
    || await markerIsActive(lockPath("recovery"));
}

async function updateCheckpoint(
  update: (targets: RecoveryTarget[]) => RecoveryTarget[],
): Promise<RecoveryTarget[]> {
  const release = await acquireLock("checkpoint");
  try {
    const current = await readCheckpoint();
    const targets = update(current?.targets ?? []);
    await writeCheckpoint(targets);
    return targets;
  } finally {
    await release();
  }
}

async function mergeCheckpoint(observed: RecoveryTarget[]): Promise<RecoveryTarget[]> {
  return updateCheckpoint((current) => mergeTargets(current, observed));
}

async function removeCheckpointPane(paneId: string): Promise<RecoveryTarget[]> {
  return updateCheckpoint((current) => current.filter((target) => target.paneId !== paneId));
}

function createReport(
  reportCommand: RecoveryReport["command"],
  startedAt: string,
  records: RecoveryRecord[],
  checkpointPresent: boolean,
  checkpointPanes: number,
): RecoveryReport {
  return {
    version: 2,
    command: reportCommand,
    startedAt,
    finishedAt: new Date().toISOString(),
    healthy: records.every((record) => record.after === "healthy"),
    checkpoint: checkpointPresent ? "present" : "absent",
    checkpointPanes,
    eligiblePanes: records.length,
    repairedPanes: records.filter((record) => (
      record.action === "started" || record.action === "replaced"
    )).length,
    records,
  };
}

async function checkpointLiveAgents(
  client: HerdrClient,
  config: Awaited<ReturnType<typeof loadConfig>>,
): Promise<void> {
  const observed = await captureTargets(client, config);
  const targets = await mergeCheckpoint(observed);
  process.stdout.write(
    `Herdr recovery ${PLUGIN_VERSION}\nObserved live panes: ${observed.length}\nCheckpointed panes: ${targets.length}\n`,
  );
}

interface PluginEvent {
  event?: string;
  data?: {
    pane_id?: string;
    released?: boolean;
  };
}

async function checkpointEvent(
  client: HerdrClient,
  config: Awaited<ReturnType<typeof loadConfig>>,
): Promise<void> {
  const raw = process.env.HERDR_PLUGIN_EVENT_JSON;
  if (!raw) return;
  const event = JSON.parse(raw) as PluginEvent;
  const paneId = event.data?.pane_id;
  if (!paneId) return;

  const removesPane = event.event === "pane.closed"
    || (event.event === "pane.agent_detected" && event.data?.released === true);
  if (removesPane) {
    if (!await recoveryIsActive()) await removeCheckpointPane(paneId);
    return;
  }

  await sleep(500);
  const observed = await captureTargets(client, config, new Set([paneId]));
  if (observed.length > 0) await mergeCheckpoint(observed);
}

async function loadTargets(
  client: HerdrClient,
  config: Awaited<ReturnType<typeof loadConfig>>,
): Promise<{ checkpointPresent: boolean; targets: RecoveryTarget[] }> {
  const checkpoint = await readCheckpoint();
  const observed = await captureTargets(client, config);
  const targets = observed.length > 0
    ? await mergeCheckpoint(observed)
    : checkpoint?.targets ?? [];
  return {
    checkpointPresent: checkpoint !== null || observed.length > 0,
    targets,
  };
}

async function runRecoveryCommand(
  client: HerdrClient,
  config: Awaited<ReturnType<typeof loadConfig>>,
  recoveryCommand: "audit" | "recover",
): Promise<RecoveryReport> {
  const startedAt = new Date().toISOString();
  const { checkpointPresent, targets } = await loadTargets(client, config);
  const records = recoveryCommand === "audit"
    ? await auditTargets(client, config, targets)
    : await recoverTargets(client, config, targets);
  if (recoveryCommand === "recover") {
    const observed = await captureTargets(client, config);
    if (observed.length > 0) await mergeCheckpoint(observed);
  }
  return createReport(
    recoveryCommand,
    startedAt,
    records,
    checkpointPresent,
    targets.length,
  );
}

async function runStartup(
  client: HerdrClient,
  config: Awaited<ReturnType<typeof loadConfig>>,
): Promise<RecoveryReport> {
  const startedAt = new Date().toISOString();
  const startedMs = Date.now();
  await writeFile(startupMarkerPath(), `${process.pid} ${startedAt}\n`, { mode: 0o600 });

  try {
    if (config.startupCaptureDelayMs > 0) await sleep(config.startupCaptureDelayMs);
    const checkpoint = await readCheckpoint();
    const observedBeforeRestore = await captureTargets(client, config);
    const targets = observedBeforeRestore.length > 0
      ? await mergeCheckpoint(observedBeforeRestore)
      : checkpoint?.targets ?? [];

    const remainingDelay = config.startupDelayMs - (Date.now() - startedMs);
    if (remainingDelay > 0) await sleep(remainingDelay);

    const records = await recoverTargetsWithRetries(client, config, targets);
    const observedAfterRestore = await captureTargets(client, config);
    if (observedAfterRestore.length > 0) await mergeCheckpoint(observedAfterRestore);
    return createReport(
      "startup",
      startedAt,
      records,
      checkpoint !== null || targets.length > 0,
      targets.length,
    );
  } finally {
    try {
      await unlink(startupMarkerPath());
    } catch (error) {
      if ((error as NodeJS.ErrnoException).code !== "ENOENT") throw error;
    }
  }
}

async function run(): Promise<void> {
  if (command === "last-report") {
    await showLastReport();
    return;
  }
  if (!configDirectory) throw new Error("HERDR_PLUGIN_CONFIG_DIR is not set");

  const config = await loadConfig(configDirectory);
  const client = new HerdrClient();

  if (command === "checkpoint-event") {
    await checkpointEvent(client, config);
    return;
  }
  if (command === "checkpoint") {
    await checkpointLiveAgents(client, config);
    return;
  }
  if (command !== "audit" && command !== "recover" && command !== "startup") {
    throw new Error(
      "Usage: main.ts <audit|recover|startup|checkpoint|checkpoint-event|last-report>",
    );
  }

  const releaseLock = await acquireLock("recovery");
  try {
    const report = command === "startup"
      ? await runStartup(client, config)
      : await runRecoveryCommand(client, config, command);
    await saveReport(report);
    process.stdout.write(formatReport(report));

    if (!report.healthy) {
      if (command === "startup") {
        await client.notifyFailure(
          report.records.filter((record) => record.after !== "healthy").length,
        );
      }
      process.exitCode = 1;
    }
  } finally {
    await releaseLock();
  }
}

run().catch((error) => {
  process.stderr.write(`herdr-recovery: ${(error as Error).message}\n`);
  process.exitCode = 1;
});
