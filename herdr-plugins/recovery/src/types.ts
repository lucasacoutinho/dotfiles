export type SupportedAgent = "claude" | "codex";

export interface AgentSessionInfo {
  source: string;
  agent: string;
  kind: string;
  value: string;
}

export interface PaneInfo {
  pane_id: string;
  terminal_id: string;
  workspace_id: string;
  tab_id: string;
  cwd?: string | null;
  foreground_cwd?: string | null;
  agent?: string | null;
  agent_session?: AgentSessionInfo | null;
}

export interface PaneProcess {
  pid: number;
  name: string;
  argv?: string[] | null;
  argv0?: string | null;
  cmdline?: string | null;
  cwd?: string | null;
}

export interface PaneProcessInfo {
  pane_id: string;
  shell_pid?: number | null;
  foreground_process_group_id?: number | null;
  foreground_processes?: PaneProcess[];
}

export interface AgentPolicy {
  enabled: boolean;
  resumeArgs: string[];
  replaceWrongArgs: boolean;
}

export interface RecoveryConfig {
  startupDelayMs: number;
  startupCaptureDelayMs: number;
  startupAttempts: number;
  retryDelayMs: number;
  processExitTimeoutMs: number;
  startTimeoutMs: number;
  maxParallel: number;
  agents: Record<SupportedAgent, AgentPolicy>;
}

export interface RecoveryTarget {
  paneId: string;
  terminalId: string;
  workspaceId: string;
  tabId: string;
  cwd: string | null;
  agent: SupportedAgent;
  sessionId: string;
  capturedFrom: "official" | "argv";
}

export interface RecoveryCheckpoint {
  version: 1;
  savedAt: string;
  targets: RecoveryTarget[];
}

export type AssessmentStatus =
  | "healthy"
  | "missing"
  | "wrong_args"
  | "conflict"
  | "busy"
  | "unsupported"
  | "error";

export interface Assessment {
  pane: PaneInfo;
  agent: SupportedAgent;
  sessionId: string;
  status: AssessmentStatus;
  message: string;
  expectedArgs: string[];
  processInfo?: PaneProcessInfo;
  agentProcess?: PaneProcess;
}

export type RecoveryAction =
  | "none"
  | "started"
  | "replaced"
  | "skipped"
  | "failed";

export interface RecoveryRecord {
  paneId: string;
  workspaceId: string;
  tabId: string;
  cwd: string | null;
  agent: SupportedAgent;
  sessionId: string;
  before: AssessmentStatus;
  after: AssessmentStatus;
  action: RecoveryAction;
  message: string;
}

export interface RecoveryReport {
  version: 2;
  command: "audit" | "recover" | "startup";
  startedAt: string;
  finishedAt: string;
  healthy: boolean;
  checkpoint: "present" | "absent";
  checkpointPanes: number;
  eligiblePanes: number;
  repairedPanes: number;
  records: RecoveryRecord[];
}
