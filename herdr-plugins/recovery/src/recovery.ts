import {
  classifyPane,
  eligibleAgent,
  paneWithTarget,
  recoveryAgentName,
  shellOwnsForeground,
} from "./core";
import type {
  Assessment,
  PaneInfo,
  PaneProcessInfo,
  RecoveryConfig,
  RecoveryRecord,
  RecoveryTarget,
  SupportedAgent,
} from "./types";

export interface RecoveryClient {
  listPanes(): Promise<PaneInfo[]>;
  processInfo(paneId: string): Promise<PaneProcessInfo>;
  startAgent(
    paneId: string,
    name: string,
    agent: SupportedAgent,
    arguments_: string[],
    timeoutMs: number,
  ): Promise<void>;
  terminateForeground(processInfo: PaneProcessInfo, processIds: number[]): void;
}

const sleep = (milliseconds: number) => new Promise((resolve) => {
  setTimeout(resolve, milliseconds);
});

async function mapLimit<T, R>(
  values: T[],
  limit: number,
  operation: (value: T) => Promise<R>,
): Promise<R[]> {
  const results = new Array<R>(values.length);
  let nextIndex = 0;

  async function worker(): Promise<void> {
    while (nextIndex < values.length) {
      const index = nextIndex;
      nextIndex += 1;
      results[index] = await operation(values[index]);
    }
  }

  await Promise.all(
    Array.from({ length: Math.min(limit, values.length) }, () => worker()),
  );
  return results;
}

async function assessPane(
  client: RecoveryClient,
  pane: PaneInfo,
  config: RecoveryConfig,
): Promise<Assessment> {
  const agent = eligibleAgent(pane, config);
  if (!agent || !pane.agent_session) {
    throw new Error(`Pane ${pane.pane_id} is not eligible for recovery`);
  }

  try {
    const processInfo = await client.processInfo(pane.pane_id);
    const assessment = classifyPane(pane, processInfo, config);
    if (!assessment) {
      throw new Error(`Pane ${pane.pane_id} lost its recovery session metadata`);
    }
    return assessment;
  } catch (error) {
    return {
      pane,
      agent,
      sessionId: pane.agent_session.value,
      status: "error",
      message: (error as Error).message,
      expectedArgs: [],
    };
  }
}

async function waitForShell(
  client: RecoveryClient,
  paneId: string,
  timeoutMs: number,
): Promise<boolean> {
  const deadline = Date.now() + timeoutMs;
  while (Date.now() < deadline) {
    const processInfo = await client.processInfo(paneId);
    const pane = (await client.listPanes()).find((entry) => entry.pane_id === paneId);
    if (pane && !pane.agent && shellOwnsForeground(processInfo)) {
      return true;
    }
    await sleep(250);
  }
  return false;
}

function missingTargetRecord(target: RecoveryTarget): RecoveryRecord {
  return {
    paneId: target.paneId,
    workspaceId: target.workspaceId,
    tabId: target.tabId,
    cwd: target.cwd,
    agent: target.agent,
    sessionId: target.sessionId,
    before: "error",
    after: "error",
    action: "failed",
    message: "The checkpointed pane is not present in the restored topology",
  };
}

async function assessTargets(
  client: RecoveryClient,
  config: RecoveryConfig,
  targets: RecoveryTarget[],
): Promise<{ assessments: Assessment[]; missing: RecoveryRecord[] }> {
  const panes = new Map((await client.listPanes()).map((pane) => [pane.pane_id, pane]));
  const missing: RecoveryRecord[] = [];
  const eligible = [] as PaneInfo[];

  for (const target of targets) {
    const pane = panes.get(target.paneId);
    if (
      !pane
      || pane.workspace_id !== target.workspaceId
      || pane.tab_id !== target.tabId
    ) {
      missing.push(missingTargetRecord(target));
      continue;
    }
    eligible.push(paneWithTarget(pane, target));
  }

  return {
    assessments: await mapLimit(
      eligible,
      config.maxParallel,
      (pane) => assessPane(client, pane, config),
    ),
    missing,
  };
}

function record(
  assessment: Assessment,
  after: Assessment["status"],
  action: RecoveryRecord["action"],
  message: string,
): RecoveryRecord {
  return {
    paneId: assessment.pane.pane_id,
    workspaceId: assessment.pane.workspace_id,
    tabId: assessment.pane.tab_id,
    cwd: assessment.pane.foreground_cwd ?? assessment.pane.cwd ?? null,
    agent: assessment.agent,
    sessionId: assessment.sessionId,
    before: assessment.status,
    after,
    action,
    message,
  };
}

async function verifyAfterStart(
  client: RecoveryClient,
  assessment: Assessment,
  config: RecoveryConfig,
  action: "started" | "replaced",
): Promise<RecoveryRecord> {
  const verified = await assessPane(client, assessment.pane, config);
  if (verified.status === "healthy") {
    return record(assessment, "healthy", action, verified.message);
  }

  return record(
    assessment,
    verified.status,
    "failed",
    `Agent launch completed but verification failed: ${verified.message}`,
  );
}

async function repairPane(
  client: RecoveryClient,
  assessment: Assessment,
  config: RecoveryConfig,
): Promise<RecoveryRecord> {
  if (assessment.status === "healthy") {
    return record(assessment, "healthy", "none", assessment.message);
  }

  if (assessment.status === "missing") {
    try {
      await client.startAgent(
        assessment.pane.pane_id,
        recoveryAgentName(assessment.agent, assessment.pane.pane_id),
        assessment.agent,
        assessment.expectedArgs,
        config.startTimeoutMs,
      );
      return verifyAfterStart(client, assessment, config, "started");
    } catch (error) {
      return record(assessment, "error", "failed", (error as Error).message);
    }
  }

  if (
    assessment.status === "wrong_args"
    && config.agents[assessment.agent].replaceWrongArgs
    && assessment.processInfo
    && assessment.agentProcess
  ) {
    try {
      const matchingProcessIds = (assessment.processInfo.foreground_processes ?? [])
        .filter((process) => process.argv?.includes(assessment.sessionId))
        .map((process) => process.pid);
      client.terminateForeground(assessment.processInfo, matchingProcessIds);
      if (!await waitForShell(
        client,
        assessment.pane.pane_id,
        config.processExitTimeoutMs,
      )) {
        return record(
          assessment,
          "wrong_args",
          "failed",
          "The old agent did not return to its shell after SIGTERM",
        );
      }

      await client.startAgent(
        assessment.pane.pane_id,
        recoveryAgentName(assessment.agent, assessment.pane.pane_id),
        assessment.agent,
        assessment.expectedArgs,
        config.startTimeoutMs,
      );
      return verifyAfterStart(client, assessment, config, "replaced");
    } catch (error) {
      return record(assessment, "error", "failed", (error as Error).message);
    }
  }

  return record(assessment, assessment.status, "skipped", assessment.message);
}

export async function audit(
  client: RecoveryClient,
  config: RecoveryConfig,
): Promise<RecoveryRecord[]> {
  const panes = (await client.listPanes()).filter((pane) => eligibleAgent(pane, config));
  const assessments = await mapLimit(
    panes,
    config.maxParallel,
    (pane) => assessPane(client, pane, config),
  );
  return assessments.map((assessment) => record(
    assessment,
    assessment.status,
    "none",
    assessment.message,
  ));
}

export async function recover(
  client: RecoveryClient,
  config: RecoveryConfig,
): Promise<RecoveryRecord[]> {
  const panes = (await client.listPanes()).filter((pane) => eligibleAgent(pane, config));
  const assessments = await mapLimit(
    panes,
    config.maxParallel,
    (pane) => assessPane(client, pane, config),
  );
  return mapLimit(
    assessments,
    config.maxParallel,
    (assessment) => repairPane(client, assessment, config),
  );
}

export async function recoverWithRetries(
  client: RecoveryClient,
  config: RecoveryConfig,
): Promise<RecoveryRecord[]> {
  let records: RecoveryRecord[] = [];

  for (let attempt = 1; attempt <= config.startupAttempts; attempt += 1) {
    records = await recover(client, config);
    if (records.every((entry) => entry.after === "healthy")) {
      break;
    }
    if (attempt < config.startupAttempts) {
      await sleep(config.retryDelayMs);
    }
  }

  return records;
}

export async function auditTargets(
  client: RecoveryClient,
  config: RecoveryConfig,
  targets: RecoveryTarget[],
): Promise<RecoveryRecord[]> {
  const { assessments, missing } = await assessTargets(client, config, targets);
  return [
    ...assessments.map((assessment) => record(
      assessment,
      assessment.status,
      "none",
      assessment.message,
    )),
    ...missing,
  ];
}

export async function recoverTargets(
  client: RecoveryClient,
  config: RecoveryConfig,
  targets: RecoveryTarget[],
): Promise<RecoveryRecord[]> {
  const { assessments, missing } = await assessTargets(client, config, targets);
  return [
    ...await mapLimit(
      assessments,
      config.maxParallel,
      (assessment) => repairPane(client, assessment, config),
    ),
    ...missing,
  ];
}

export async function recoverTargetsWithRetries(
  client: RecoveryClient,
  config: RecoveryConfig,
  targets: RecoveryTarget[],
): Promise<RecoveryRecord[]> {
  let records: RecoveryRecord[] = [];

  for (let attempt = 1; attempt <= config.startupAttempts; attempt += 1) {
    records = await recoverTargets(client, config, targets);
    if (records.every((entry) => entry.after === "healthy")) break;
    if (attempt < config.startupAttempts) await sleep(config.retryDelayMs);
  }

  return records;
}
