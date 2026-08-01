import { describe, expect, test } from "bun:test";
import { DEFAULT_CONFIG } from "../src/config";
import {
  recover,
  recoverTargets,
  type RecoveryClient,
} from "../src/recovery";
import type {
  PaneInfo,
  PaneProcessInfo,
  RecoveryTarget,
  SupportedAgent,
} from "../src/types";

const sessionId = "019fb2de-638a-7d30-ab84-5e13f0869dff";

function pane(): PaneInfo {
  return {
    pane_id: "w1:p2",
    terminal_id: "term-2",
    workspace_id: "w1",
    tab_id: "w1:t2",
    cwd: "/workspace",
    agent_session: {
      source: "herdr:codex",
      agent: "codex",
      kind: "id",
      value: sessionId,
    },
  };
}

function shellProcess(): PaneProcessInfo {
  return {
    pane_id: "w1:p2",
    shell_pid: 100,
    foreground_process_group_id: 100,
    foreground_processes: [{ pid: 100, name: "zsh", argv: ["zsh"] }],
  };
}

function codexProcess(arguments_: string[]): PaneProcessInfo {
  return {
    pane_id: "w1:p2",
    shell_pid: 100,
    foreground_process_group_id: 200,
    foreground_processes: [{
      pid: 200,
      name: "node",
      argv: ["node", "/opt/@openai/codex/bin/codex.js", ...arguments_],
    }],
  };
}

class FakeClient implements RecoveryClient {
  processes: PaneProcessInfo;
  starts: string[][] = [];
  terminations = 0;

  constructor(processes: PaneProcessInfo) {
    this.processes = processes;
  }

  async listPanes(): Promise<PaneInfo[]> {
    return [pane()];
  }

  async processInfo(): Promise<PaneProcessInfo> {
    return structuredClone(this.processes);
  }

  async startAgent(
    _paneId: string,
    _name: string,
    _agent: SupportedAgent,
    arguments_: string[],
    _timeoutMs: number,
  ): Promise<void> {
    this.starts.push(arguments_);
    this.processes = codexProcess(arguments_);
  }

  terminateForeground(_processInfo: PaneProcessInfo, _processIds: number[]): void {
    this.terminations += 1;
    this.processes = shellProcess();
  }
}

function checkpointTarget(): RecoveryTarget {
  return {
    paneId: "w1:p2",
    terminalId: "term-2",
    workspaceId: "w1",
    tabId: "w1:t2",
    cwd: "/workspace",
    agent: "codex",
    sessionId,
    capturedFrom: "argv",
  };
}

describe("recovery coordinator", () => {
  test("starts a missing session in its existing pane and verifies it", async () => {
    const client = new FakeClient(shellProcess());
    const records = await recover(client, structuredClone(DEFAULT_CONFIG));

    expect(client.starts).toEqual([["--yolo", "resume", sessionId]]);
    expect(client.terminations).toBe(0);
    expect(records[0].action).toBe("started");
    expect(records[0].after).toBe("healthy");
  });

  test("replaces the expected plain Codex resume with yolo", async () => {
    const client = new FakeClient(codexProcess(["resume", sessionId]));
    const records = await recover(client, structuredClone(DEFAULT_CONFIG));

    expect(client.terminations).toBe(1);
    expect(client.starts).toEqual([["--yolo", "resume", sessionId]]);
    expect(records[0].action).toBe("replaced");
    expect(records[0].after).toBe("healthy");
  });

  test("does not terminate a live Codex process with another session", async () => {
    const client = new FakeClient(codexProcess(["--yolo", "resume", "another-session"]));
    const records = await recover(client, structuredClone(DEFAULT_CONFIG));

    expect(client.terminations).toBe(0);
    expect(client.starts).toHaveLength(0);
    expect(records[0].action).toBe("skipped");
    expect(records[0].after).toBe("conflict");
  });

  test("recovers from a checkpoint after Herdr drops agent-session metadata", async () => {
    const client = new FakeClient(shellProcess());
    client.listPanes = async () => [{
      pane_id: "w1:p2",
      terminal_id: "term-2-after-reboot",
      workspace_id: "w1",
      tab_id: "w1:t2",
      cwd: "/workspace",
    }];

    const records = await recoverTargets(
      client,
      structuredClone(DEFAULT_CONFIG),
      [checkpointTarget()],
    );

    expect(client.starts).toEqual([["--yolo", "resume", sessionId]]);
    expect(records[0].after).toBe("healthy");
  });

  test("waits for Herdr to release the old agent identity before relaunching", async () => {
    const client = new FakeClient(codexProcess(["resume", sessionId]));
    let releasePolls = 0;
    client.listPanes = async () => {
      const value = pane();
      if (client.terminations > 0 && releasePolls++ === 0) value.agent = "codex";
      return [value];
    };

    const records = await recover(client, structuredClone(DEFAULT_CONFIG));

    expect(releasePolls).toBeGreaterThan(1);
    expect(client.starts).toEqual([["--yolo", "resume", sessionId]]);
    expect(records[0].after).toBe("healthy");
  });
});
