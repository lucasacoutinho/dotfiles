# Herdr agent recovery

This plugin keeps a private checkpoint of Codex and Claude pane/session
mappings. After Herdr restores a session, it starts missing agents in the same
panes and verifies their live arguments.

Codex recovery uses `codex --yolo resume <session-id>` by default. Claude uses
`claude --resume <session-id>`.

## Safety rules

The plugin checkpoints official `herdr:codex` and `herdr:claude` session
references. For resumed agents, it can also recover the session ID from an
exact configured resume-argument sequence. It does not search agent databases,
reopen subagents, read conversations, or load authentication files.

It will not replace an agent that is running a different session. It also
leaves panes owned by another foreground process alone. When Codex resumes the
expected session without `--yolo`, the plugin sends `SIGTERM` only to that
pane's foreground process group. If the agent shares the shell's process group,
it signals only processes whose arguments contain the expected session ID. It
then waits for the shell and starts the same session with the configured
arguments. It never sends `SIGKILL`.

## Commands

Herdr runs the recovery action automatically after a cold server start. The
startup action captures Herdr's early restore state after two seconds, waits 20
seconds for native restore to settle, then makes at most three recovery
attempts. Its own checkpoint remains available even if Herdr clears transient
agent-session metadata.

Run the actions manually when needed:

```bash
herdr plugin action invoke lucas.recovery.audit
herdr plugin action invoke lucas.recovery.recover
herdr plugin action invoke lucas.recovery.checkpoint
herdr plugin action invoke lucas.recovery.last-report
```

`audit` does not change panes. `recover` starts missing sessions and applies
the configured replacement policy. `checkpoint` merges every currently
verifiable live agent into the durable checkpoint and removes entries for panes
that no longer exist. Agent-detected and pane-closed events keep it current
between manual runs. Every recovery run
stores a session-specific report in the plugin state directory with mode
`0600`. Session-specific locks stop overlapping recovery and checkpoint writes.

## Configuration

The built-in defaults need no config file. To override them, copy
`config.example.json` to the plugin config directory:

```bash
config_dir="$(herdr plugin config-dir lucas.recovery)"
cp ~/.local/share/herdr-plugins/recovery/config.example.json "$config_dir/config.json"
```

Home Manager builds the plugin as a standalone Bun executable. The installed
plugin runs `bin/herdr-recovery`; it does not load TypeScript or require Bun at
runtime. For development, run `bun test`. The Nix package owns the production
build because it supplies Bun's pristine upstream executable to `bun build
--compile`; using the Nix-patched Bun executable as the embedded runtime makes
the resulting standalone payload invalid.

Set Claude's `resumeArgs` to the following only if every restored Claude pane
should skip permission checks:

```json
["--dangerously-skip-permissions", "--resume", "{session}"]
```

Keep exactly one `{session}` placeholder in each argument list. Set
`replaceWrongArgs` to `true` when the plugin should replace a matching live
session whose arguments differ from the policy.

## Development

Run the tests with Bun:

```bash
bun test
```
