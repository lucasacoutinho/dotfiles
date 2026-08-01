import { describe, expect, test } from "bun:test";
import {
  mergeTargets,
  parseCheckpoint,
  reconcileLiveTargets,
} from "../src/checkpoint";
import { DEFAULT_CONFIG } from "../src/config";
import { targetFromPane } from "../src/core";
import type { PaneInfo, RecoveryTarget } from "../src/types";

const sessionId = "019fb2de-638a-7d30-ab84-5e13f0869dff";

function target(paneId: string, capturedFrom: RecoveryTarget["capturedFrom"]): RecoveryTarget {
  return {
    paneId,
    terminalId: `term-${paneId}`,
    workspaceId: "w1",
    tabId: `w1:t${paneId}`,
    cwd: "/workspace",
    agent: "codex",
    sessionId,
    capturedFrom,
  };
}

describe("durable checkpoint", () => {
  test("extracts a session from exact live resume arguments without pane metadata", () => {
    const pane: PaneInfo = {
      pane_id: "w1:p1",
      terminal_id: "term-1",
      workspace_id: "w1",
      tab_id: "w1:t1",
      cwd: "/workspace",
      agent: "codex",
    };
    const observed = targetFromPane(pane, {
      pane_id: pane.pane_id,
      shell_pid: 100,
      foreground_process_group_id: 200,
      foreground_processes: [{
        pid: 200,
        name: "node",
        argv: ["node", "/opt/@openai/codex/bin/codex.js", "--yolo", "resume", sessionId],
      }],
    }, DEFAULT_CONFIG);

    expect(observed?.sessionId).toBe(sessionId);
    expect(observed?.capturedFrom).toBe("argv");
  });

  test("prefers an official session reference for a fresh launch", () => {
    const pane: PaneInfo = {
      pane_id: "w1:p1",
      terminal_id: "term-1",
      workspace_id: "w1",
      tab_id: "w1:t1",
      agent_session: {
        source: "herdr:codex",
        agent: "codex",
        kind: "id",
        value: sessionId,
      },
    };
    const observed = targetFromPane(pane, {
      pane_id: pane.pane_id,
      foreground_processes: [{ pid: 200, name: "codex", argv: ["codex", "--yolo"] }],
    }, DEFAULT_CONFIG);

    expect(observed?.capturedFrom).toBe("official");
  });

  test("prefers exact live resume arguments over stale official metadata", () => {
    const staleSessionId = "019f0000-0000-7000-8000-000000000000";
    const pane: PaneInfo = {
      pane_id: "w1:p1",
      terminal_id: "term-1",
      workspace_id: "w1",
      tab_id: "w1:t1",
      agent_session: {
        source: "herdr:codex",
        agent: "codex",
        kind: "id",
        value: staleSessionId,
      },
    };
    const observed = targetFromPane(pane, {
      pane_id: pane.pane_id,
      foreground_processes: [{
        pid: 200,
        name: "codex",
        argv: ["codex", "--yolo", "resume", sessionId],
      }],
    }, DEFAULT_CONFIG);

    expect(observed?.sessionId).toBe(sessionId);
    expect(observed?.capturedFrom).toBe("argv");
  });

  test("merges newly observed panes without dropping older targets", () => {
    const existing = [target("w1:p1", "official"), target("w1:p2", "official")];
    const replacement = target("w1:p1", "argv");
    expect(mergeTargets(existing, [replacement])).toEqual([
      replacement,
      existing[1],
    ]);
  });

  test("prunes checkpoint targets whose panes no longer exist", () => {
    const existing = [target("w1:p1", "official"), target("w1:p2", "official")];
    const replacement = target("w1:p1", "argv");
    expect(reconcileLiveTargets(existing, [replacement], new Set(["w1:p1"]))).toEqual([
      replacement,
    ]);
  });

  test("rejects an invalid checkpoint instead of treating it as empty", () => {
    expect(parseCheckpoint({ version: 1, savedAt: "now", targets: [{}] })).toBeNull();
  });
});
