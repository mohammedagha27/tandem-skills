# Codex CLI Protocol (verified on codex-cli 0.146.0, 2026-08-21)

The one safe, non-hanging way to run OpenAI Codex as a read-only critic from Claude Code.
Every line here exists because the naive version fails silently or dangerously.

## Preflight (once per run)

1. `codex --version` — these mechanics are verified on ≥ 0.146; on other versions re-check the
   flags below before trusting them.
2. Authenticated via a prior `codex login` (ChatGPT account is fine). Auth/model errors get
   surfaced to the user — never silently retried.
3. Do NOT pin `-m`. The user's `~/.codex/config.toml` model is used. Echo it once (read the
   `model` line; absent = "CLI default") so the user knows who's reviewing.
4. Run from the **target repo root**. Codex refuses to run outside a trusted directory (a git
   repo) unless `--skip-git-repo-check` is passed — prefer being in the repo over the flag.

## Fresh session (first round)

Write the prompt to a temp file — never inline-quote it (quoting bugs + stdin discipline).
Use a **fresh reply file per call** (a stale reply file from a prior round makes a failed call
look successful and hands you last round's verdict):

```bash
P=$(mktemp); REPLY=$(mktemp)
cat >"$P" <<'EOF'
<prompt text>
EOF
codex exec -s read-only --json -o "$REPLY" - <"$P" >/tmp/tandem-stream.jsonl 2>/tmp/tandem-stderr.log
grep -o '"thread_id":"[^"]*"' /tmp/tandem-stream.jsonl | head -1
```

- `- <"$P"` feeds the prompt via stdin. This avoids the non-TTY hang: `codex exec` reads stdin
  in addition to any prompt argument, and under a non-interactive driver it blocks forever
  waiting for EOF at ~0% CPU. Feeding a file gives immediate EOF.
- Capture the full stream to a file, then parse the `thread_id` from it. Do NOT pipe the live
  stream through `grep | head -1` — `head` exiting mid-stream SIGPIPEs the pipeline and can
  kill Codex mid-review.
- The reply lands in `$REPLY`. Read that file; never parse the JSONL stream for content.
- **Success contract:** non-empty `$REPLY` + a `thread.started` event in the stream. Anything
  less is a failed run (auth, model, untrusted dir): read the stderr log, surface the real
  error. stderr routinely carries cosmetic MCP/OAuth noise — judge by the contract, not by
  stderr being non-empty.

## Resumed session (every later round)

```bash
REPLY=$(mktemp)
codex exec resume "$THREAD_ID" -c sandbox_mode="read-only" --json \
  -o "$REPLY" - <"$P2" >/dev/null 2>>/tmp/tandem-stderr.log
```

- **`resume` rejects `-s`.** Without `-c sandbox_mode="read-only"` it inherits
  `~/.codex/config.toml`, which may be `danger-full-access` — Codex could then WRITE files
  mid-loop. This is the single most important safety line in the protocol.
- Resuming the same thread means Codex remembers its earlier critiques and won't re-litigate
  settled points — cheaper and sharper than fresh sessions.
- Never resume with `--last`: parallel sessions make it grab the wrong thread, and a
  missing/garbage id can silently fall back to the most recent session instead of erroring.
  Echo the explicit `$THREAD_ID` into the command visibly.

## Timeouts and the failure ladder

Pass `timeout: 600000` on the Bash tool call for every `codex exec` / `resume` (the default
2-minute tool timeout kills real reviews mid-run; 10 minutes is the ceiling). For reviews of
large diffs, prefer `run_in_background: true` and read the reply file on completion. When a
background run finishes, lead your next message with a loud banner (`🔔 CODEX FINISHED —
<what>`) before any analysis — the user isn't watching tool calls.

One unified ladder for every failure kind (timeout, crash, missing success contract, double
verdict-miss):

1. **First failure:** tell the user what failed. One deliberate recovery is sanctioned: a
   **fresh session** (`codex exec`, new thread) whose prompt carries a 3-bullet catch-up
   (current plan/diff pointer, settled points, rejected findings + reasons) — never a blind
   retry of the same call, and never a resume of a thread that just failed.
2. **Second consecutive failure** (recovery included): Codex is **unavailable** for this run.
   Fall back to solo mode (see `sparring.md`), record the degradation, stop hammering the CLI.

Failed calls and the recovery attempt never count toward any round cap; the interrupted round
re-runs (in whichever mode you're now in).

## Verdict contract

Every review prompt must demand severity-tagged findings and a machine-checkable last line:

> Tag each finding `[BLOCKING]` (would break correctness/security/data), `[MATERIAL]`
> (meaningful quality/robustness gap), or `[MINOR]` (nit or polish). End your reply with
> EXACTLY one line: `VERDICT: BLOCKING`, `VERDICT: MATERIAL`, `VERDICT: MINOR`, or
> `VERDICT: CLEAN`. The verdict covers this round's findings PLUS any earlier finding of
> yours that you still maintain after seeing the response to it — but NOT findings you have
> conceded, and NOT disputed points you have nothing new to add on (list those instead under
> `STILL DISPUTED:` so they are tracked, not re-argued).

Parse the verdict from the **last line** of the reply file (it may lack a trailing newline).
A reply without a parseable verdict counts as `MATERIAL` and gets one retry-with-reminder in
the same session; a second miss is a failed round — enter the failure ladder above.
`STILL DISPUTED` items go to `state.md § Disagreements`, not back into the argument.

Long replies: extract the findings and verdict into your triage; don't quote the reply
wholesale into context. The full text is already on disk if anyone needs it.
