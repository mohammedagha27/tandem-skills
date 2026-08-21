---
name: tandem-review
description: 'Cross-model review of a whole feature branch by OpenAI Codex (read-only), with Claude verifying every finding before it reaches the user. Use when the user invokes /tandem-review, says "have codex review this branch/feature/PR", "cross-model review before I open the PR", "second model opinion on this branch''s changes", or as the pre-PR gate of the tandem workflow. Reviews the entire feature (merge-base to HEAD plus working tree) — not just the latest commit or diff. NOT for reviewing plans before code exists (use /tandem spar), NOT for single-function or snippet review, NOT for plain review requests that never ask for a codex/cross-model opinion, and NOT a replacement for human PR review.'
---

# Tandem-Review — Whole-Feature Cross-Model Review

Codex reads the complete feature — every commit since the merge-base plus uncommitted work —
and attacks it. Claude then **verifies each finding against the code before presenting it**:
cross-model review is only valuable if hallucinated findings die before they waste anyone's
time. Codex never writes a file; Claude writes nothing either on a review-only invocation (no
"cleanup" stashes or commits of the user's tree). Fixes are applied only when the invoker
explicitly says so afterwards — the sole exception is the tandem ship phase, whose playbook
carries that consent; no other caller, human or programmatic, inherits it.

## Scope resolution

1. Determine the base deterministically: the branch's configured upstream merge target if the
   repo records one, else the repo's default branch (`gh repo view --json defaultBranchRef` or
   `origin/HEAD`). If more than one plausible integration branch exists (`main` AND `develop`)
   and nothing settles it, that IS ambiguous — ask. A user-supplied base/range/branch always
   wins (but "review this branch" names the *subject*, not the base).
2. The scope is the working-tree diff against the merge-base — `git diff <merge-base>` (this
   covers committed AND uncommitted changes) — plus untracked files from `git status`, listed
   separately. Echo the scope (base, branch, commit count, files touched) before launching.
   Sanity-check it: an empty or one-commit scope on a long-lived branch usually means a wrong
   base (or a just-merged integration branch) — confirm before declaring "nothing to review".
3. If a `.tandem/<slug>/` directory exists for this branch, tell Codex to read its `plan.md`
   and `state.md` — that upgrades the review with requirements coverage and plan-deviation
   checks. Standalone (no tandem context) reviews simply skip those dimensions.

## Protocol

Full mechanics: read `../tandem/references/codex-protocol.md` (this skill family installs
together). If that file is missing, the essentials that must never be violated:

- Preflight `codex --version` (these flags verified on ≥ 0.146) and run from the repo root
  (Codex refuses untrusted, non-git directories).
- Prompt via temp file + stdin, fresh reply file per call:
  `codex exec -s read-only --json -o "$REPLY" - <"$P" >stream.jsonl 2>stderr.log`.
  Never inline-quote; stdin-feed prevents the non-TTY EOF hang. Parse `thread_id` from the
  captured stream file (not a live `grep | head` pipe — SIGPIPE kills the run).
- **Success contract:** non-empty reply file + a `thread.started` event; anything less is a
  failed run — read the stderr log, surface the real error, stop. stderr noise alone is not
  failure.
- On **resume**: `codex exec resume "$THREAD_ID" -c sandbox_mode="read-only" …` — resume
  rejects `-s`, and without the `-c` override Codex may inherit write access from user config.
  Never `--last`; always the explicit captured thread id.
- `timeout: 600000` on every call; big diffs → `run_in_background: true`. Tripped timeout =
  failed run: surface it, don't retry blind.
- Verdict parses from the **last line** of the reply file (may lack a trailing newline);
  a reply with no parseable verdict counts as MATERIAL and gets one retry-with-reminder, then
  is a failed run.
- Don't pin `-m`; echo the config model once so the user knows who's reviewing.

## The review prompt

```
You are reviewing a complete feature before it becomes a PR. You are read-only.
Scope: run `git diff <merge-base>` (all changes, committed and uncommitted, vs the base)
and `git status` for untracked files; read any repo file you need. Review the ENTIRE scope —
if you skim any touched file, say which.
[If tandem context: The agreed plan is .tandem/<slug>/plan.md and the requirement/decision
record is .tandem/<slug>/state.md — check the implementation against BOTH.]

Examine: correctness; requirements coverage [if plan available]; architecture fit with the
surrounding codebase; regression risk to existing behavior; unhandled edge cases; security;
performance; maintainability; test coverage and test QUALITY (do the tests pin behavior or
just execute code?); unnecessary complexity to cut; deviations from the agreed plan [if
available]. Separate observed facts from inferences. For each finding: severity tag
([BLOCKING]/[MATERIAL]/[MINOR]), file:line where applicable, what breaks and when, a one-line
concrete fix. End with EXACTLY one line: VERDICT: BLOCKING | MATERIAL | MINOR | CLEAN.
```

After the reply: spot-check coverage against your own files-touched list — if a heavily
touched file shows no trace in the review (no finding, no mention), ask in the same session
whether it was read before trusting silence about it.

## Triage — Claude's half of the review

Every finding lands in exactly one bucket, worked in severity order:

1. **Confirmed** — you opened the cited code (or, for findings without a file:line, checked
   the claim against the codebase) and it holds.
2. **Rejected** — the finding mis-reads the code; record the evidence.
3. **Pre-existing** — real, but present at the merge-base and untouched by this feature;
   reported separately, not this feature's debt.
4. **Unverifiable inference** — Codex labeled it an inference and you can't cheaply settle it;
   pass it through clearly labeled as such, never dressed up as a confirmed finding.

Then **recompute the verdict from confirmed findings only** — Codex's headline verdict is not
repeated if triage gutted it. Present: confirmed (by severity, with your fix plan), rejected
(with evidence), pre-existing, unverifiable — preserving Codex's fact/inference boundaries.

**Standalone invocation:** STOP after presenting. Ask which findings to fix — never
auto-apply review fixes to a branch you were only asked to review.
**Called from tandem's ship phase:** fix confirmed findings per that phase's rules, resuming
the SAME Codex session for re-review over the fix delta.

## Bounds & failure

- Fix-and-re-review cycles ≤ 2, counted **per feature branch** — a fresh Codex session, a new
  merge-base echo, or a standalone-then-approved flow does not reset the counter. The cap
  applies equally when a standalone user approves fixes. After the cap, remaining disputes go
  to the user; each further cycle happens only on their explicit per-cycle ask.
- Codex unavailable (per the protocol's failure ladder — one fresh-session recovery, then
  done): say so and offer a Claude-only pass against the same examine-list, clearly labeled
  as single-model.
- Truly empty scope (base verified correct, no diff, nothing uncommitted): report "nothing to
  review" — don't launch.
