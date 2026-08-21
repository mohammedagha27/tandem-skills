# Build — implementing the frozen plan

The plan survived sparring and the gate; now execute it without silently drifting from it.

## Setup

0. **Clean-tree gate:** `git status` before anything. Clean, or dirty only with
   workflow-owned files (`.tandem/…`)? Proceed. Anything else is unrelated work and is never
   absorbed silently — it would contaminate the branch, the baseline snapshot, the feature
   diff, and every commit. Ask the user (in every autonomy mode): stash it, move this work to
   an isolated worktree, or explicitly bless named files into scope; record the choice in
   `state.md`.
1. **Branch:** never build on the default branch. Resolve the integration branch
   deterministically: the repo's default branch (`gh repo view --json defaultBranchRef` or
   `origin/HEAD`) unless the repo's docs say features cut from elsewhere; if both `main` and
   `develop` exist and nothing settles it, ask once. Create `feat/<slug>` (or the repo's
   naming convention) from it, and record both `branch:` and `base:` in `state.md`.
2. **Baseline snapshot:** run the test suite (or the relevant slice, if the full suite is
   impractical — say which) BEFORE the first change. Record failing test ids in
   `state.md § Build → Baseline failures`. This is what later separates "we broke it" from
   "it was broken" — you cannot reconstruct it after the fact.
3. Re-read `plan.md`. If executing in a fresh session, the plan plus `state.md` must be enough;
   if they aren't, that's a plan defect — repair it via the deviation protocol below (a
   mechanical gap is move 1; a hole that reopens a decision is move 2). The freeze means no
   *silent* change, not no change.

## Execution model — inline or per-task subagents

Classify once, after re-reading the frozen plan, and record the choice and reason in
`state.md § Build → Execution` (the user can force it with the invocation-only override
`execution=inline|subagents`):

- **Inline** — you implement in-session: one or two tightly coupled tasks, or mechanical work.
- **Subagents** — a fresh implementer per task: several independently executable tasks, or a
  build large enough that accumulating its diffs would crowd the orchestrator's context.
  Batch tiny same-shape edits into a single dispatch. Sequential by default — never run
  implementers whose file sets could conflict in parallel.

The subagent loop (adapted from Jesse Vincent's superpowers `subagent-driven-development`,
MIT — see THIRD-PARTY-NOTICES; state.md remains the ONLY ledger — no separate progress file):

1. **Brief:** write `.tandem/<slug>/briefs/TASK-<n>.md` from the plan's task entry plus any
   state context it needs. The worker gets the brief and the repo — never this conversation
   and never the whole plan. A brief that can't stand alone is a plan defect: fix the plan
   via the deviation protocol before dispatching.
2. **Dispatch** a fresh implementer subagent with the brief path. It implements, writes the
   tests the brief calls for, runs the brief's verification command, self-reviews, writes a
   detailed report to `.tandem/<slug>/reports/TASK-<n>.md`, and returns only a short status
   (done | blocked + why).
3. **Verify yourself:** read the diff and run the verification command — never take the
   report's word for it. Then commit and update `state.md` (task done, commit sha).
4. **Task review, sized to risk:** a task touching security, data migration, a public
   interface, or several components gets a fresh reviewer subagent (inputs: brief + diff;
   output: severity-tagged findings). For mechanical tasks, your own diff inspection plus a
   green verification command is enough. One focused correction + scoped re-review per task —
   not a fix marathon; a task still failing after that reopens the plan via the deviation
   protocol.

Isolated worktree: when the clean-tree gate parked unrelated work, or the user wants their
checkout undisturbed, run the build in `git worktree add` isolation on the feature branch —
subagent execution composes with it unchanged.

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
   do it, log `V<n>` in `state.md § Build → Deviations`, and annotate the affected step in
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
