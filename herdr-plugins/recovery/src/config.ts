import { readFile } from "node:fs/promises";
import { join } from "node:path";
import type {
  AgentPolicy,
  RecoveryConfig,
  SupportedAgent,
} from "./types";

export const DEFAULT_CONFIG: RecoveryConfig = {
  startupDelayMs: 20_000,
  startupCaptureDelayMs: 2_000,
  startupAttempts: 3,
  retryDelayMs: 3_000,
  processExitTimeoutMs: 5_000,
  startTimeoutMs: 45_000,
  maxParallel: 3,
  agents: {
    codex: {
      enabled: true,
      resumeArgs: ["--yolo", "resume", "{session}"],
      replaceWrongArgs: true,
    },
    claude: {
      enabled: true,
      resumeArgs: ["--resume", "{session}"],
      replaceWrongArgs: false,
    },
  },
};

const AGENTS: SupportedAgent[] = ["codex", "claude"];

function integerInRange(
  value: unknown,
  fallback: number,
  minimum: number,
  maximum: number,
): number {
  return Number.isInteger(value) && Number(value) >= minimum && Number(value) <= maximum
    ? Number(value)
    : fallback;
}

function loadPolicy(value: unknown, fallback: AgentPolicy): AgentPolicy {
  if (value === null || typeof value !== "object") {
    return fallback;
  }

  const candidate = value as Record<string, unknown>;
  const resumeArgs = Array.isArray(candidate.resumeArgs)
    && candidate.resumeArgs.every((argument) => typeof argument === "string")
    && candidate.resumeArgs.filter((argument) => argument === "{session}").length === 1
    ? [...candidate.resumeArgs]
    : [...fallback.resumeArgs];

  return {
    enabled: typeof candidate.enabled === "boolean" ? candidate.enabled : fallback.enabled,
    resumeArgs,
    replaceWrongArgs: typeof candidate.replaceWrongArgs === "boolean"
      ? candidate.replaceWrongArgs
      : fallback.replaceWrongArgs,
  };
}

export function mergeConfig(value: unknown): RecoveryConfig {
  if (value === null || typeof value !== "object") {
    return structuredClone(DEFAULT_CONFIG);
  }

  const candidate = value as Record<string, unknown>;
  const agentConfig = candidate.agents !== null && typeof candidate.agents === "object"
    ? candidate.agents as Record<string, unknown>
    : {};
  const agents = {} as Record<SupportedAgent, AgentPolicy>;

  for (const agent of AGENTS) {
    agents[agent] = loadPolicy(agentConfig[agent], DEFAULT_CONFIG.agents[agent]);
  }

  return {
    startupDelayMs: integerInRange(
      candidate.startupDelayMs,
      DEFAULT_CONFIG.startupDelayMs,
      0,
      300_000,
    ),
    startupCaptureDelayMs: integerInRange(
      candidate.startupCaptureDelayMs,
      DEFAULT_CONFIG.startupCaptureDelayMs,
      0,
      30_000,
    ),
    startupAttempts: integerInRange(
      candidate.startupAttempts,
      DEFAULT_CONFIG.startupAttempts,
      1,
      5,
    ),
    retryDelayMs: integerInRange(
      candidate.retryDelayMs,
      DEFAULT_CONFIG.retryDelayMs,
      0,
      60_000,
    ),
    processExitTimeoutMs: integerInRange(
      candidate.processExitTimeoutMs,
      DEFAULT_CONFIG.processExitTimeoutMs,
      500,
      30_000,
    ),
    startTimeoutMs: integerInRange(
      candidate.startTimeoutMs,
      DEFAULT_CONFIG.startTimeoutMs,
      3_001,
      300_000,
    ),
    maxParallel: integerInRange(
      candidate.maxParallel,
      DEFAULT_CONFIG.maxParallel,
      1,
      8,
    ),
    agents,
  };
}

export async function loadConfig(configDirectory: string): Promise<RecoveryConfig> {
  try {
    const contents = await readFile(join(configDirectory, "config.json"), "utf8");
    return mergeConfig(JSON.parse(contents));
  } catch (error) {
    if ((error as NodeJS.ErrnoException).code === "ENOENT") {
      return structuredClone(DEFAULT_CONFIG);
    }

    throw new Error(`Cannot load recovery config: ${(error as Error).message}`);
  }
}
