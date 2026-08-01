import { basename } from "node:path";
import type {
  AgentPolicy,
  Assessment,
  PaneInfo,
  PaneProcess,
  PaneProcessInfo,
  RecoveryConfig,
  RecoveryTarget,
  SupportedAgent,
} from "./types";

const SUPPORTED_AGENTS = new Set<SupportedAgent>(["codex", "claude"]);

export function isSupportedAgent(value: string): value is SupportedAgent {
  return SUPPORTED_AGENTS.has(value as SupportedAgent);
}

export function eligibleAgent(
  pane: PaneInfo,
  config: RecoveryConfig,
): SupportedAgent | null {
  const session = pane.agent_session;
  if (!session || !isSupportedAgent(session.agent)) {
    return null;
  }

  if (!config.agents[session.agent].enabled) {
    return null;
  }

  if (
    session.source !== `herdr:${session.agent}`
    || session.kind !== "id"
    || session.value.trim() === ""
  ) {
    return null;
  }

  return session.agent;
}

export function expectedResumeArgs(policy: AgentPolicy, sessionId: string): string[] {
  return policy.resumeArgs.map((argument) => (
    argument === "{session}" ? sessionId : argument
  ));
}

function containsSequence(values: string[], expected: string[]): boolean {
  if (expected.length === 0 || expected.length > values.length) {
    return false;
  }

  for (let start = 0; start <= values.length - expected.length; start += 1) {
    if (expected.every((value, offset) => values[start + offset] === value)) {
      return true;
    }
  }

  return false;
}

function executableTokenMatches(token: string, agent: SupportedAgent): boolean {
  const normalized = token.toLowerCase().replaceAll("\\", "/");
  const filename = basename(normalized);

  if (agent === "codex") {
    return filename === "codex"
      || filename === "codex.js"
      || /(^|[/@._-])codex([/._-]|$)/.test(normalized);
  }

  return filename === "claude"
    || /(^|[/@._-])claude(?:-code)?([/._-]|$)/.test(normalized);
}

export function processLooksLikeAgent(
  process: PaneProcess,
  agent: SupportedAgent,
): boolean {
  const commandTokens = [
    process.name,
    process.argv0 ?? "",
    ...(process.argv ?? []).slice(0, 4),
  ].filter(Boolean);

  if (commandTokens.some((token) => executableTokenMatches(token, agent))) {
    return true;
  }

  return process.argv == null
    && typeof process.cmdline === "string"
    && executableTokenMatches(process.cmdline, agent);
}

export function extractSessionId(
  arguments_: string[],
  resumeArgs: string[],
): string | null {
  if (resumeArgs.length === 0 || resumeArgs.length > arguments_.length) {
    return null;
  }

  for (let start = 0; start <= arguments_.length - resumeArgs.length; start += 1) {
    let sessionId: string | null = null;
    let matches = true;

    for (let offset = 0; offset < resumeArgs.length; offset += 1) {
      const expected = resumeArgs[offset];
      const actual = arguments_[start + offset];
      if (expected === "{session}") {
        if (actual.trim() === "") {
          matches = false;
          break;
        }
        sessionId = actual;
      } else if (actual !== expected) {
        matches = false;
        break;
      }
    }

    if (matches && sessionId) {
      return sessionId;
    }
  }

  return null;
}

function recoveryTarget(
  pane: PaneInfo,
  agent: SupportedAgent,
  sessionId: string,
  capturedFrom: RecoveryTarget["capturedFrom"],
): RecoveryTarget {
  return {
    paneId: pane.pane_id,
    terminalId: pane.terminal_id,
    workspaceId: pane.workspace_id,
    tabId: pane.tab_id,
    cwd: pane.foreground_cwd ?? pane.cwd ?? null,
    agent,
    sessionId,
    capturedFrom,
  };
}

export function targetFromPane(
  pane: PaneInfo,
  processInfo: PaneProcessInfo,
  config: RecoveryConfig,
): RecoveryTarget | null {
  const foreground = processInfo.foreground_processes ?? [];
  for (const agent of SUPPORTED_AGENTS) {
    if (!config.agents[agent].enabled) continue;
    const process = foreground.find((entry) => processLooksLikeAgent(entry, agent));
    if (!process?.argv) continue;
    const sessionId = extractSessionId(process.argv, config.agents[agent].resumeArgs);
    if (sessionId) {
      return recoveryTarget(pane, agent, sessionId, "argv");
    }
  }

  const officialAgent = eligibleAgent(pane, config);
  if (officialAgent && pane.agent_session) {
    return recoveryTarget(
      pane,
      officialAgent,
      pane.agent_session.value,
      "official",
    );
  }

  return null;
}

export function paneWithTarget(
  pane: PaneInfo,
  target: RecoveryTarget,
): PaneInfo {
  return {
    ...pane,
    agent_session: {
      source: `herdr:${target.agent}`,
      agent: target.agent,
      kind: "id",
      value: target.sessionId,
    },
  };
}

function processArguments(process: PaneProcess): string[] {
  return process.argv ?? [];
}

export function shellOwnsForeground(processInfo: PaneProcessInfo): boolean {
  const foreground = processInfo.foreground_processes ?? [];
  if (foreground.length === 0) {
    return true;
  }

  return processInfo.shell_pid != null
    && foreground.every((process) => process.pid === processInfo.shell_pid);
}

function resumeMarker(arguments_: string[]): boolean {
  return arguments_.some((argument) => (
    argument === "resume"
    || argument === "--resume"
    || argument.startsWith("--resume=")
  ));
}

function liveSessionMatchesPolicy(
  arguments_: string[],
  expectedArgs: string[],
  sessionId: string,
): boolean {
  const requiredArguments = expectedArgs.filter((argument) => (
    argument !== sessionId && argument !== "resume" && argument !== "--resume"
  ));
  return requiredArguments.every((argument) => arguments_.includes(argument));
}

export function classifyPane(
  pane: PaneInfo,
  processInfo: PaneProcessInfo,
  config: RecoveryConfig,
): Assessment | null {
  const agent = eligibleAgent(pane, config);
  if (!agent || !pane.agent_session) {
    return null;
  }

  const sessionId = pane.agent_session.value;
  const expectedArgs = expectedResumeArgs(config.agents[agent], sessionId);
  const foreground = processInfo.foreground_processes ?? [];
  const agentProcess = foreground.find((process) => processLooksLikeAgent(process, agent));

  if (agentProcess) {
    const arguments_ = processArguments(agentProcess);
    if (!arguments_.includes(sessionId)) {
      if (!resumeMarker(arguments_)) {
        const policyMatches = liveSessionMatchesPolicy(arguments_, expectedArgs, sessionId);
        return {
          pane,
          agent,
          sessionId,
          status: policyMatches ? "healthy" : "wrong_args",
          message: policyMatches
            ? `The live ${agent} session matches the configured launch policy`
            : `The live ${agent} session does not match the configured launch policy`,
          expectedArgs,
          processInfo,
          agentProcess,
        };
      }

      return {
        pane,
        agent,
        sessionId,
        status: "conflict",
        message: `A ${agent} process is running with a different session`,
        expectedArgs,
        processInfo,
        agentProcess,
      };
    }

    if (!containsSequence(arguments_, expectedArgs)) {
      return {
        pane,
        agent,
        sessionId,
        status: "wrong_args",
        message: `The restored ${agent} session does not match the configured launch policy`,
        expectedArgs,
        processInfo,
        agentProcess,
      };
    }

    return {
      pane,
      agent,
      sessionId,
      status: "healthy",
      message: `The ${agent} session is running with the expected arguments`,
      expectedArgs,
      processInfo,
      agentProcess,
    };
  }

  if (shellOwnsForeground(processInfo)) {
    return {
      pane,
      agent,
      sessionId,
      status: "missing",
      message: `The pane restored to a shell without its ${agent} session`,
      expectedArgs,
      processInfo,
    };
  }

  return {
    pane,
    agent,
    sessionId,
    status: "busy",
    message: "Another foreground process owns the pane",
    expectedArgs,
    processInfo,
  };
}

export function recoveryAgentName(agent: SupportedAgent, paneId: string): string {
  const suffix = paneId.toLowerCase().replace(/[^a-z0-9_-]/g, "-").slice(-14);
  return `restore-${agent}-${suffix}`.slice(0, 32).replace(/-+$/g, "");
}
