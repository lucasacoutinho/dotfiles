import { spawn } from "node:child_process";
import type {
  PaneInfo,
  PaneProcessInfo,
  SupportedAgent,
} from "./types";

interface HerdrEnvelope<T> {
  result: T;
}

interface PaneListResult {
  type: "pane_list";
  panes: PaneInfo[];
}

interface PaneProcessInfoResult {
  type: "pane_process_info";
  process_info: PaneProcessInfo;
}

export type TerminationPlan =
  | { kind: "process-group"; id: number }
  | { kind: "processes"; ids: number[] };

export function planTermination(
  processInfo: PaneProcessInfo,
  processIds: number[],
): TerminationPlan {
  const processGroupId = processInfo.foreground_process_group_id;
  if (
    processGroupId != null
    && processGroupId > 1
    && processGroupId !== processInfo.shell_pid
  ) {
    return { kind: "process-group", id: processGroupId };
  }

  const verifiedProcessIds = [...new Set(processIds)]
    .filter((pid) => pid > 1 && pid !== processInfo.shell_pid)
    .sort((left, right) => right - left);
  if (verifiedProcessIds.length === 0) {
    throw new Error("Refusing to terminate an unverified foreground process");
  }

  return { kind: "processes", ids: verifiedProcessIds };
}

function capped(value: string): string {
  const trimmed = value.trim();
  return trimmed.length > 800 ? `${trimmed.slice(0, 800)}...` : trimmed;
}

export class HerdrClient {
  readonly binary: string;

  constructor(binary = process.env.HERDR_BIN_PATH ?? "herdr") {
    this.binary = binary;
  }

  private run<T>(arguments_: string[], timeoutMs = 15_000): Promise<T> {
    return new Promise((resolve, reject) => {
      const child = spawn(this.binary, arguments_, {
        env: process.env,
        stdio: ["ignore", "pipe", "pipe"],
      });
      const stdout: Buffer[] = [];
      const stderr: Buffer[] = [];
      let timedOut = false;

      const timer = setTimeout(() => {
        timedOut = true;
        child.kill("SIGTERM");
      }, timeoutMs);

      child.stdout.on("data", (chunk: Buffer) => stdout.push(chunk));
      child.stderr.on("data", (chunk: Buffer) => stderr.push(chunk));
      child.on("error", (error) => {
        clearTimeout(timer);
        reject(error);
      });
      child.on("close", (code) => {
        clearTimeout(timer);
        const output = Buffer.concat(stdout).toString("utf8");
        const errorOutput = Buffer.concat(stderr).toString("utf8");

        if (timedOut) {
          reject(new Error(`Herdr command timed out: ${arguments_.join(" ")}`));
          return;
        }

        if (code !== 0) {
          reject(new Error(
            `Herdr command failed (${code ?? "signal"}): ${capped(errorOutput || output)}`,
          ));
          return;
        }

        try {
          resolve((JSON.parse(output) as HerdrEnvelope<T>).result);
        } catch (error) {
          reject(new Error(
            `Herdr returned invalid JSON: ${(error as Error).message}; ${capped(output)}`,
          ));
        }
      });
    });
  }

  async listPanes(): Promise<PaneInfo[]> {
    const result = await this.run<PaneListResult>(["pane", "list"]);
    return result.panes;
  }

  async processInfo(paneId: string): Promise<PaneProcessInfo> {
    const result = await this.run<PaneProcessInfoResult>([
      "pane",
      "process-info",
      "--pane",
      paneId,
    ]);
    return result.process_info;
  }

  async startAgent(
    paneId: string,
    name: string,
    agent: SupportedAgent,
    arguments_: string[],
    timeoutMs: number,
  ): Promise<void> {
    await this.run(
      [
        "agent",
        "start",
        name,
        "--kind",
        agent,
        "--pane",
        paneId,
        "--timeout",
        String(timeoutMs),
        "--",
        ...arguments_,
      ],
      timeoutMs + 5_000,
    );
  }

  terminateForeground(processInfo: PaneProcessInfo, processIds: number[]): void {
    const plan = planTermination(processInfo, processIds);
    if (plan.kind === "process-group") {
      process.kill(-plan.id, "SIGTERM");
      return;
    }

    for (const pid of plan.ids) {
      try {
        process.kill(pid, "SIGTERM");
      } catch (error) {
        if ((error as NodeJS.ErrnoException).code !== "ESRCH") throw error;
      }
    }
  }

  async notifyFailure(count: number): Promise<void> {
    try {
      await this.run([
        "notification",
        "show",
        "Herdr recovery needs attention",
        "--body",
        `${count} agent pane${count === 1 ? "" : "s"} could not be restored`,
        "--sound",
        "request",
      ]);
    } catch {
      // The report and plugin command log remain available if notifications fail.
    }
  }
}
