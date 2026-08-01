import { targetFromPane } from "./core";
import type { RecoveryClient } from "./recovery";
import type {
  RecoveryCheckpoint,
  RecoveryConfig,
  RecoveryTarget,
  SupportedAgent,
} from "./types";

const SUPPORTED_AGENTS = new Set<SupportedAgent>(["codex", "claude"]);

function validTarget(value: unknown): value is RecoveryTarget {
  if (value === null || typeof value !== "object") return false;
  const target = value as Record<string, unknown>;
  return typeof target.paneId === "string"
    && typeof target.terminalId === "string"
    && typeof target.workspaceId === "string"
    && typeof target.tabId === "string"
    && (target.cwd === null || typeof target.cwd === "string")
    && typeof target.agent === "string"
    && SUPPORTED_AGENTS.has(target.agent as SupportedAgent)
    && typeof target.sessionId === "string"
    && target.sessionId.trim() !== ""
    && (target.capturedFrom === "official" || target.capturedFrom === "argv");
}

export function parseCheckpoint(value: unknown): RecoveryCheckpoint | null {
  if (value === null || typeof value !== "object") return null;
  const checkpoint = value as Record<string, unknown>;
  if (
    checkpoint.version !== 1
    || typeof checkpoint.savedAt !== "string"
    || !Array.isArray(checkpoint.targets)
    || !checkpoint.targets.every(validTarget)
  ) {
    return null;
  }

  return {
    version: 1,
    savedAt: checkpoint.savedAt,
    targets: checkpoint.targets.map((target) => ({ ...target } as RecoveryTarget)),
  };
}

export function mergeTargets(
  existing: RecoveryTarget[],
  observed: RecoveryTarget[],
): RecoveryTarget[] {
  const targets = new Map(existing.map((target) => [target.paneId, target]));
  for (const target of observed) targets.set(target.paneId, target);
  return [...targets.values()].sort((left, right) => (
    left.workspaceId.localeCompare(right.workspaceId)
    || left.tabId.localeCompare(right.tabId)
    || left.paneId.localeCompare(right.paneId)
  ));
}

export function reconcileLiveTargets(
  existing: RecoveryTarget[],
  observed: RecoveryTarget[],
  livePaneIds: Set<string>,
): RecoveryTarget[] {
  return mergeTargets(existing, observed).filter((target) => (
    livePaneIds.has(target.paneId)
  ));
}

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

export async function captureTargets(
  client: RecoveryClient,
  config: RecoveryConfig,
  paneIds?: Set<string>,
): Promise<RecoveryTarget[]> {
  const panes = (await client.listPanes()).filter((pane) => (
    paneIds === undefined || paneIds.has(pane.pane_id)
  ));
  const targets = await mapLimit(panes, config.maxParallel, async (pane) => {
    try {
      return targetFromPane(pane, await client.processInfo(pane.pane_id), config);
    } catch {
      return null;
    }
  });
  return targets.filter((target): target is RecoveryTarget => target !== null);
}
