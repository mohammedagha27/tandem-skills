---
name: tandem-review
description: 'Cross-model review of a whole feature branch by OpenAI Codex (read-only), with Claude verifying every finding before it reaches the user. Use when the user invokes /tandem-review, says "have codex review this branch/feature/PR", "cross-model review before I open the PR", "second model opinion on these changes", or as the pre-PR gate of the tandem workflow. Reviews the entire feature (merge-base to HEAD plus working tree) — not just the latest commit or diff. NOT for reviewing plans before code exists (use /tandem spar) and NOT a replacement for human PR review.'
---

# Tandem-Review — Whole-Feature Cross-Model Review

Codex reads the complete feature — every commit since the merge-base plus uncommitted work —
and attacks it. Claude then **verifies each finding against the code before presenting it**:
cross-model review is only valuable if hallucinated findings die before they waste anyone's
time. Codex never writes a file, and this skill never auto-fixes anything without the caller's
say-so (the tandem ship phase is a caller that says so; a human invoking this standalone is not).

## Scope resolution

1. Determine the base: merge-base of HEAD with the repo's integration branch (`main`/`master`/
   `develop` — check which exists; ambiguous → ask). User-supplied range/branch wins.
2. The review scope is `git diff <base>...HEAD` + `git status` uncommitted changes. Echo the
   scope (base, branch, commit count, files touched) before launching so a wrong-base review
   never burns a run.
3. If a `.tandem/<slug>/` directory exists for this branch, tell Codex to read its `plan.md`
   and `state.md` — that upgrades the review with requirements coverage and plan-deviation
   checks. Standalone (no tandem context) reviews simply skip those dimensions.

## Protocol

Full mechanics: read `../tandem/references/codex-protocol.md` (this skill family installs
together). If that file is missing, the essentials that must never be violated:

- Run from the repo root. Prompt via temp file + stdin: `codex exec -s read-only --json -o
  <reply-file> - <"$P"`. Never inline-quote; stdin-feed prevents the non-TTY EOF hang.
- Capture `thread_id` from the `thread.started` event; reply is in the `-o` file.
- On **resume**: `codex exec resume "$THREAD_ID" -c sandbox_mode="read-only" …` — resume
  rejects `-s`, and without the `-c` override Codex may inherit write access from user config.
- `timeout: 600000` on every call; big diffs → `run_in_background: true`. Tripped timeout =
  failed run: surface it, don't retry blind.
- Don't pin `-m`; echo the config model once so the user knows who's reviewing.

## The review prompt

```
You are reviewing a complete feature before it becomes a PR. You are read-only.
Scope: all changes from <base> to HEAD on branch <branch>, plus uncommitted changes —
run `git diff <base>...HEAD` and `git status` yourself, and read any repo file you need.
[If tandem context: The agreed plan is .tandem/<slug>/plan.md and the requirement/decision
record is .tandem/<slug>/state.md — check the implementation against BOTH.]

Examine: correctness; requirements coverage [if plan available]; architecture fit with the
surrounding codebase; regression risk to existing behavior; unhandled edge cases; security;
performance; maintainability; test coverage and test QUALITY (do the tests pin behavior or
just execute code?); unnecessary complexity to cut; deviations from the agreed plan [if
available]. Separate observed facts from inferences. For each finding: severity tag
([BLOCKING]/[MATERIAL]/[MINOR]), file:line, what breaks and when, a one-line concrete fix.
End with EXACTLY one line: VERDICT: BLOCKING | MATERIAL | MINOR | CLEAN.
```

## Triage — Claude's half of the review

For every finding, in severity order:

1. **Verify it**: open the cited file:line, check the claim against the actual code. Findings
   that mis-read the code are marked `rejected (wrong: <evidence>)`. Findings that are real but
   pre-existing (present at the base, untouched by this feature) are marked `pre-existing` and
   reported separately — they are not this feature's debt.
2. Present the verified list: confirmed findings (by severity, with your fix plan), rejected
   findings (with evidence), pre-existing issues. Preserve Codex's fact/inference distinction.
3. **Standalone invocation:** STOP after presenting. Ask which findings to fix — never
   auto-apply review fixes to a branch you were only asked to review.
   **Called from tandem's ship phase:** fix confirmed findings per that phase's rules (bounded
   at 2 fix-and-re-review cycles), resuming the SAME Codex session for re-review ("here's what
   changed since your review: …").

## Bounds & failure

- Re-review cycles ≤ 2, then remaining disputes go to the user with both positions.
- Codex unavailable (missing, unauthenticated, 2 consecutive timeouts): say so and offer a
  Claude-only pass against the same checklist, clearly labeled as single-model.
- A reply with no parseable VERDICT line: one retry-with-reminder in the same session, then
  treat as a failed run.
- Empty diff (base = HEAD, nothing uncommitted): report "nothing to review" — don't launch.
