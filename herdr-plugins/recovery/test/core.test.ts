import { describe, expect, test } from "bun:test";
import { DEFAULT_CONFIG, mergeConfig } from "../src/config";
import {
  classifyPane,
  eligibleAgent,
  recoveryAgentName,
  shellOwnsForeground,
} from "../src/core";
import type { PaneInfo, PaneProcessInfo } from "../src/types";

const sessionId = "019fb2de-638a-7d30-ab84-5e13f0869dff";

function pane(agent = "codex"): PaneInfo {
  return {
    pane_id: "w7:p12",
    terminal_id: "term-12",
    workspace_id: "w7",
    tab_id: "w7:t12",
    cwd: "/home/lucas/project",
    agent_session: {
      source: `herdr:${agent}`,
      agent,
      kind: "id",
      value: sessionId,
    },
  };
}

function processInfo(argv: string[]): PaneProcessInfo {
  return {
    pane_id: "w7:p12",
    shell_pid: 100,
    foreground_process_group_id: 200,
    foreground_processes: [{
      pid: 200,
      name: "node",
      argv,
    }],
  };
}

describe("pane classification", () => {
  test("accepts a Codex node wrapper with the exact yolo resume command", () => {
    const assessment = classifyPane(
      pane(),
      processInfo(["node", "/opt/@openai/codex/bin/codex.js", "--yolo", "resume", sessionId]),
      DEFAULT_CONFIG,
    );
    expect(assessment?.status).toBe("healthy");
  });

  test("marks Herdr's plain Codex resume as the wrong launch policy", () => {
    const assessment = classifyPane(
      pane(),
      processInfo(["node", "/opt/@openai/codex/bin/codex.js", "resume", sessionId]),
      DEFAULT_CONFIG,
    );
    expect(assessment?.status).toBe("wrong_args");
  });

  test("does not replace a different live Codex session", () => {
    const assessment = classifyPane(
      pane(),
      processInfo(["codex", "--yolo", "resume", "different-session"]),
      DEFAULT_CONFIG,
    );
    expect(assessment?.status).toBe("conflict");
  });

  test("accepts a fresh live Codex session reported by the official hook", () => {
    const assessment = classifyPane(
      pane(),
      processInfo(["codex", "--yolo"]),
      DEFAULT_CONFIG,
    );
    expect(assessment?.status).toBe("healthy");
  });

  test("marks a fresh plain Codex session as the wrong policy", () => {
    const assessment = classifyPane(
      pane(),
      processInfo(["codex"]),
      DEFAULT_CONFIG,
    );
    expect(assessment?.status).toBe("wrong_args");
  });

  test("marks an empty restored shell as missing", () => {
    const assessment = classifyPane(
      pane(),
      {
        pane_id: "w7:p12",
        shell_pid: 100,
        foreground_process_group_id: 100,
        foreground_processes: [{ pid: 100, name: "zsh", argv: ["zsh"] }],
      },
      DEFAULT_CONFIG,
    );
    expect(assessment?.status).toBe("missing");
  });

  test("leaves a pane with another foreground command alone", () => {
    const assessment = classifyPane(
      pane(),
      processInfo(["bun", "test", "--watch"]),
      DEFAULT_CONFIG,
    );
    expect(assessment?.status).toBe("busy");
  });

  test("recognizes a standard Claude resume", () => {
    const assessment = classifyPane(
      pane("claude"),
      processInfo(["node", "/opt/@anthropic-ai/claude-code/cli.js", "--resume", sessionId]),
      DEFAULT_CONFIG,
    );
    expect(assessment?.status).toBe("healthy");
  });
});

describe("recovery boundaries", () => {
  test("accepts only official pane-scoped session identities", () => {
    expect(eligibleAgent(pane(), DEFAULT_CONFIG)).toBe("codex");

    const custom = pane();
    if (custom.agent_session) custom.agent_session.source = "custom:codex";
    expect(eligibleAgent(custom, DEFAULT_CONFIG)).toBeNull();

    const pathSession = pane();
    if (pathSession.agent_session) pathSession.agent_session.kind = "path";
    expect(eligibleAgent(pathSession, DEFAULT_CONFIG)).toBeNull();
  });

  test("requires the shell process group before launching", () => {
    expect(shellOwnsForeground({
      pane_id: "w7:p12",
      shell_pid: 100,
      foreground_process_group_id: 100,
      foreground_processes: [{ pid: 100, name: "zsh" }],
    })).toBe(true);
  });

  test("does not mistake a child sharing the shell process group for an empty shell", () => {
    expect(shellOwnsForeground({
      pane_id: "w7:p12",
      shell_pid: 100,
      foreground_process_group_id: 100,
      foreground_processes: [{ pid: 200, name: "bun", argv: ["bun", "test"] }],
    })).toBe(false);
  });

  test("creates a valid stable agent name", () => {
    expect(recoveryAgentName("codex", "w7:p12")).toBe("restore-codex-w7-p12");
    expect(recoveryAgentName("codex", "workspace:with:a:very:long:pane:id").length).toBeLessThanOrEqual(32);
  });
});

describe("configuration", () => {
  test("keeps safe defaults when overrides are malformed", () => {
    const config = mergeConfig({
      startupDelayMs: -1,
      maxParallel: 100,
      agents: {
        codex: { resumeArgs: ["resume", "without-placeholder"] },
      },
    });
    expect(config.startupDelayMs).toBe(DEFAULT_CONFIG.startupDelayMs);
    expect(config.maxParallel).toBe(DEFAULT_CONFIG.maxParallel);
    expect(config.agents.codex.resumeArgs).toEqual(DEFAULT_CONFIG.agents.codex.resumeArgs);
  });

  test("accepts one session placeholder in a custom Claude policy", () => {
    const config = mergeConfig({
      agents: {
        claude: {
          resumeArgs: ["--dangerously-skip-permissions", "--resume", "{session}"],
          replaceWrongArgs: true,
        },
      },
    });
    expect(config.agents.claude.resumeArgs[0]).toBe("--dangerously-skip-permissions");
    expect(config.agents.claude.replaceWrongArgs).toBe(true);
  });
});
