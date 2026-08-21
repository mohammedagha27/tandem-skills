# Codex CLI Protocol (verified on codex-cli 0.146.0, 2026-08-21)

The one safe, non-hanging way to run OpenAI Codex as a read-only critic from Claude Code.
Every line here exists because the naive version fails silently or dangerously.

## Preflight (once per run)

1. `codex --version` — need ≥ 0.146 mechanics as documented here; on older CLIs re-verify flags.
2. Authenticated via a prior `codex login` (ChatGPT account is fine). Auth/model errors get
   surfaced to the user — never silently retried.
3. Do NOT pin `-m`. The user's `~/.codex/config.toml` model is used. Echo it once (read the
   `model` line; absent = "CLI default") so the user knows who's reviewing.
4. Run from the **target repo root**. Codex refuses to run outside a trusted directory (a git
   repo) unless `--skip-git-repo-check` is passed — prefer being in the repo over the flag.

## Fresh session (first round)

Write the prompt to a temp file — never inline-quote it (quoting bugs + stdin discipline):

```bash
P=$(mktemp)
cat >"$P" <<'EOF'
<prompt text>
EOF
codex exec -s read-only --json -o /tmp/tandem-reply.txt - <"$P" 2>/tmp/tandem-stderr.log \
  | grep -o '"thread_id":"[^"]*"' | head -1
```

- `- <"$P"` feeds the prompt via stdin. This avoids the non-TTY hang: `codex exec` reads stdin
  in addition to any prompt argument, and under a non-interactive driver it blocks forever
  waiting for EOF at ~0% CPU. Feeding a file gives immediate EOF.
- Capture the `thread_id` from the `thread.started` event — you need it for every later round.
- The reply lands in the `-o` file. Read that file; never parse the JSONL stream for content.
- stderr carries cosmetic MCP/OAuth noise on many setups — log it to a file, don't show it.
  Success = reply file exists + a `thread.started` line. Neither → failed run (auth, model,
  untrusted dir): read the stderr log, surface the real error, stop.

## Resumed session (every later round)

```bash
codex exec resume "$THREAD_ID" -c sandbox_mode="read-only" --json \
  -o /tmp/tandem-reply.txt - <"$P2" 2>>/tmp/tandem-stderr.log >/dev/null
```

- **`resume` rejects `-s`.** Without `-c sandbox_mode="read-only"` it inherits
  `~/.codex/config.toml`, which may be `danger-full-access` — Codex could then WRITE files
  mid-loop. This is the single most important safety line in the protocol.
- Resuming the same thread means Codex remembers its earlier critiques and won't re-litigate
  settled points — cheaper and sharper than fresh sessions.
- Never resume with `--last`: parallel sessions make it grab the wrong thread, and a
  missing/garbage id can silently fall back to the most recent session instead of erroring.
  Echo the explicit `$THREAD_ID` into the command visibly.

## Timeouts

Pass `timeout: 600000` on the Bash tool call for every `codex exec` / `resume` (the default
2-minute tool timeout kills real reviews mid-run; 10 minutes is the ceiling). For reviews of
large diffs, prefer `run_in_background: true` and read the `-o` file on completion. A tripped
ceiling is a **failed run**: stop, tell the user, don't retry blind. When a background run
finishes, lead your next message with a loud banner (`🔔 CODEX FINISHED — <what>`) before any
analysis — the user isn't watching tool calls.

## Verdict contract

Every review prompt must demand severity-tagged findings and a machine-checkable last line:

> Tag each finding `[BLOCKING]` (would break correctness/security/data), `[MATERIAL]`
> (meaningful quality/robustness gap), or `[MINOR]` (nit or polish). End your reply with
> EXACTLY one line: `VERDICT: BLOCKING`, `VERDICT: MATERIAL`, `VERDICT: MINOR`, or
> `VERDICT: CLEAN` — the highest severity among your unresolved findings, or CLEAN.

Parse the verdict from the **last line** of the `-o` file (it may lack a trailing newline).
A reply without a parseable verdict counts as `MATERIAL` and gets one retry-with-reminder in
the same session; a second miss is a failed round.

## Unavailability test

Codex is "unavailable" when: the binary is missing, `--version` fails, auth errors, or two
consecutive calls trip the timeout. Fall back to solo mode (see `sparring.md`) and record the
degradation — do not keep hammering the CLI.
