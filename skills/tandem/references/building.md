# Build — implementing the frozen plan

The plan survived sparring and the gate; now execute it without silently drifting from it.

## Setup

0. **Clean-tree gate:** `git status` before anything. Clean, or dirty only with
   workflow-owned files (`.tandem/…`)? Proceed. Anything else is unrelated work and is never
   absorbed silently — it would contaminate the branch, the baseline snapshot, the feature
   diff, and every commit. Ask the user (in every autonomy mode): stash it, run the *build*
   in an isolated worktree (their work stays untouched in the main checkout), or explicitly
   bless named files into scope; record the choice in `state.md`.
1. **Branch:** never build on the default branch. Resolve the integration branch
   deterministically: the repo's default branch (`gh repo view --json defaultBranchRef` or
   `origin/HEAD`) unless the repo's docs say features cut from elsewhere; if both `main` and
   `develop` exist and nothing settles it, ask once. Create `feat/<slug>` (or the repo's
   naming convention) from it, and record both `branch:` and `base:` in `state.md`.
   Building in a worktree (chosen at the gate, or because the user wants their checkout
   undisturbed)? Create it NOW, before any other step — `git worktree add <path> -b
   feat/<slug> <base>` — and run everything from here on, baseline included, inside it.
   `.tandem/<slug>/` stays in the main checkout's repo root (one source of truth); reference
   it by absolute path from the worktree.
2. **Baseline snapshot:** run the test suite (or the relevant slice, if the full suite is
   impractical — say which) BEFORE the first change. Record failing test ids in
   `state.md § Build → Baseline failures`. This is what later separates "we broke it" from
   "it was broken" — you cannot reconstruct it after the fact.
3. Re-read `plan.md`. If executing in a fresh session, the plan plus `state.md` must be enough;
   if they aren't, that's a plan defect — repair it via the deviation protocol below (a
   mechanical gap is move 1; a hole that reopens a decision is move 2). The freeze means no
   *silent* change, not no change.

## Execution model — inline or per-task subagents

The resolved `execution` sits on state's `config:` line (contract: `references/config.md`).
`inline` or `subagents` is a forced choice — honor it, reason: "set in config/invocation".
`auto` means classify here, once, after re-reading the frozen plan; either way, record the
choice and reason in `state.md § Build → Execution`:

- **Inline** — you implement in-session: one or two tasks, tightly coupled work, or anything
  mechanical.
- **Subagents** — a fresh implementer per task: several independently executable tasks, or a
  build large enough that accumulating its diffs would crowd the orchestrator's context.
- **Neither clearly fits?** Default to subagents at ≥3 independently executable tasks or any
  single task with a large expected diff; otherwise inline. Record the reason either way.

Dispatches run **sequentially** — parallel implementers aren't used (commit scoping and diff
attribution aren't worth the hazard). Tiny same-shape edits (a rename, one mechanical pattern
repeated — minutes each, not real tasks) may share one dispatch: one combined brief
`briefs/TASK-<a>+<b>.md` naming every batched TASK-id; never batch tasks whose behavior
differs.

The subagent loop (adapted from Jesse Vincent's superpowers `subagent-driven-development`,
MIT — see THIRD-PARTY-NOTICES). `state.md` remains the ONLY ledger; worker reports are
per-task working files — regenerable, never authoritative:

1. **Brief:** write `.tandem/<slug>/briefs/TASK-<n>.md` from the plan's task entry plus any
   state context it needs. The worker gets the brief and the repo — never this conversation
   and never the whole plan. Every brief ends with the worker's contract: implement and test
   exactly this task; run the brief's verification command; write a detailed report (what you
   did, deviations, caveats, anything only partially met) to
   `.tandem/<slug>/reports/TASK-<n>.md`; return only a short status (done | blocked + why);
   do NOT commit, push, or touch `state.md` — the orchestrator owns git and the ledger.
   A brief that can't stand alone is a plan defect: fix the plan via the deviation protocol
   before dispatching.
2. **Dispatch** the fresh implementer subagent with the brief path (plus the worktree path
   when one is in use).
3. **Verify yourself:** read the worker's report FIRST — deviations and caveats it noted go
   into `state.md` (§ Deviations, or a blocker to resolve) before you judge the code. Then
   read the diff and run the brief's verification command yourself — never take the report's
   word for results. Then commit and update `state.md` (task done, commit sha).
4. **Task review, sized to risk:** a task touching security, data migration, a public
   interface, or several components gets a fresh reviewer subagent (inputs: brief + diff +
   report; output: severity-tagged findings). For mechanical tasks, your own diff inspection
   plus a green verification command is enough — and when unsure whether a task is
   mechanical, it isn't: review it. The orchestrator implements corrections (re-dispatch with
   an amended brief only when the fix is itself task-sized), then one scoped re-review. Log
   the outcome in `state.md § Build → Task reviews` (fixed / rejected-with-reason /
   waived-by-user). A task still failing after its correction reopens the plan via the
   deviation protocol.

A **blocked** dispatch may leave uncommitted changes. Inspect that diff before anything else:
fold what's salvageable into the revised brief, discard the rest (`git checkout -- <task
files>`), and never dispatch the next worker onto a dirty tree.

## Execution discipline (both models)

- Work task by task; mark each done in `state.md § Build → Done` as you go.
- Honor the repo's own workflow norms and the user's standing preferences (TDD, coverage
  bars, commit conventions). The plan's test strategy section says what to test; write tests
  with the code, not as a final batch.
- Small, coherent commits at natural checkpoints — each leaves the branch green. After each
  commit, update `Last commit:`/`In progress:` in `state.md` — that pair is what makes a
  mid-build resume safe.
- Preserve existing conventions; no drive-by refactors. If the code you're touching genuinely
  blocks the work, the fix belongs in the plan (add a deviation, below) — not smuggled in.
- Verify continuously: after each step, run the focused tests for what you touched. Full-suite
  runs at checkpoints, not after every line.

## Deviations — the anti-drift rule

Reality will disagree with the plan somewhere. When it does, there are only two legal moves:

1. **Small deviation** (same intent, different mechanics — a renamed helper, an extra guard):
   do it, log `V<n>` in `state.md § Build → Deviations`, and annotate the affected task in
   `plan.md` (`> deviated: …`). Keep building.
2. **Broken assumption** (a decision D-id rests on something false; the approach can't work as
   written): STOP building on that path. Reopen the decision in `state.md`, work out the fix —
   with the user if the decision was theirs or the scope changes; a one-round Codex spot-check
   (same session if alive) is worth it when the new approach is materially different. Update
   `plan.md` and `state.md`, then continue.

What is never legal: implementing something other than the plan and leaving the plan claiming
otherwise. The dossier renders decisions and deviations from state — silent drift poisons it.

## Blocked?

Missing dependency, permission wall, an instruction that stopped making sense: stop and ask
(guided) or record the blocker in `state.md § Next` and surface it (auto). Don't guess through
blockers — a wrong guess compounds.

Exit to Ship when: every plan task is done or consciously deviated, the branch is green against
baseline, and `state.md` reflects reality.
