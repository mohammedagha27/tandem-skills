# Tandem — Validation Record

How the skills were tested before being considered done, and what the tests changed.
Method per skill-creator / superpowers:writing-skills: fresh agents with no authoring context
exercised the skills against realistic scenarios; live Codex runs verified the CLI protocol.
Interactive phases (understand-gate interviews, plan sign-off) can't be end-to-end automated,
so those paths were exercised as adversarial tabletop walkthroughs — fresh agents simulating
execution step by step and reporting every point where the instructions run out, contradict,
or permit a lazy shortcut.

## 1. Live Codex protocol smoke test (codex-cli 0.146.0, 2026-08-21)

Executed for real against a toy plan with a deliberately planted contradiction:

- `codex exec -s read-only --json -o … - <prompt` → `thread.started` captured; severity tags
  and the one-line `VERDICT:` contract were followed exactly; Codex found the planted
  stdout/stderr contradiction and tagged it `[BLOCKING]`. ✅
- Plan revised → `codex exec resume <thread> -c sandbox_mode="read-only" …` → session memory
  intact ("prior findings are addressed"), verdict `CLEAN`. ✅
- **New finding encoded into the protocol:** 0.146 refuses to run outside a trusted directory
  (a git repo) unless `--skip-git-repo-check` is passed. The first smoke run failed on exactly
  this; the protocol now mandates running from the repo root and documents the flag.
- Confirmed stderr noise (MCP/OAuth refresh errors) is cosmetic — reinforced "log stderr to a
  file, judge success by reply file + thread.started".
- Confirmed the `-o` reply file can lack a trailing newline — verdict parsing reads the last
  line rather than expecting `\n`-terminated output.

## 2. Trigger sanity panel

A fresh agent judged 12 realistic queries against only the two frontmatter descriptions:
12/12 routed correctly (including the near-misses: plan-review → tandem spar, single-function
review → neither, plain typo fix → neither). Three hardening edits were applied from its
uncertainty report:

- tandem: resume trigger made mechanical ("trigger when a `.tandem/` state directory exists").
- tandem: spar mode explicitly covers standalone design debates with Codex.
- tandem-review: explicit NOT-trigger for plain review requests that never ask for a
  cross-model opinion.

## 3. Tabletop walkthroughs (fresh subagents, adversarial brief)

| Scenario (goal §Validation) | Agent focus | Outcome |
|---|---|---|
| 1. Simple feature request + 6. full implementation with review | Full-lifecycle walkthrough | see findings below |
| 2. Ticket ID with repo context (fetch failure path) + 4. ambiguous feature | Intake/understand loopholes | see findings below |
| 7. Codex unavailable mid-loop + 8. resume after interruption | Failure/resume | see findings below |
| 5. Planning-only + modes + config precedence | Mode routing | see findings below |
| tandem-review standalone + adversarial loophole hunt | Review skill | see findings below |

### Findings and fixes

**Modes + config agent** (all fixed):
- Config arg shorthands (`rounds=`, `review=`) were used in examples but never declared as
  aliases of `max_rounds`/`codex_review` — a literal agent would ignore them. → Aliases and
  unknown-key behavior now declared in the config section.
- Spar mode had no working-state contract (no slug, no state.md, unclear whether a
  user-supplied plan file is mutated in place). → Spar mode now runs a minimal intake, copies
  the plan into `.tandem/<slug>/plan.md`, never edits the source doc, stops after presenting
  the hardened plan, ends at phase `planned`.
- Plan mode's "dossier-of-plan" contradicted the dossier template (required PR link,
  verification, final diff). → Plan/spar modes explicitly skip the dossier phase; the plan +
  state are their artifacts; phase ends `planned` so resume can continue into Build.
- Dossier commit branch with `pr=off` or a declined PR was unspecified (and the post-dossier
  push could silently not happen). → Dossier playbook now specifies: feature branch, and push
  after committing whenever the branch was already pushed.
- `.gitignore` referent ambiguous (`.tandem/` wholesale would ignore the committed
  `config.md`). → Now specified: ignore `.tandem/*/` (state dirs), keep `.tandem/config.md`.
- `ci=on` with `pr=off` silently no-ops. → Stated explicitly.

**Failure/resume agent** (all fixed):
- Three files gave three different timeout/unavailability thresholds, with no sanctioned path
  from first failure to second. → One unified ladder in `codex-protocol.md`: first failure →
  one fresh-session recovery with a 3-bullet catch-up (never a blind retry); second
  consecutive failure of any kind → solo mode. Failed calls never consume review rounds.
- `spar:` state field couldn't record degradation history (thread id lost on solo switch). →
  `solo (was codex thread <id>, degraded round <n>)`.
- Mid-build resume couldn't distinguish claimed from real progress and could destroy
  uncommitted work. → `base:`, `Last commit: <sha> (step)`, `In progress: … uncommitted:
  yes|no` added to the state template; resume protocol now reads plan.md explicitly, inspects
  dirty trees before touching them, and defines resume-time config precedence.
- Deadlock tie-break conflicted with `autonomy=auto` and could double-present disagreements. →
  Deadlock always pauses for the user in every mode, presented once, merged into the plan
  gate; post-tie-break the cap stays spent and the dossier notes the unreviewed revision.
- Solo rounds (fresh subagents, no session memory) would re-litigate settled points. → Solo
  prompt contract: plan path + settled D-ids + rejected findings with reasons.

**Intake/ambiguity agent** (fixed; two minor items consciously skipped):
- The Understand gate keyed on a self-assigned `open` label that auto mode was licensed to
  rewrite — a lazy agent could relabel every open as an assumption and never ask. → One
  operational scope test defined in SKILL.md and referenced by state.md ("two reasonable
  readings deliver different things"), `scope: yes` items never convertible in any mode,
  auto-conversions record their basis, assumptions resurface at the plan gate and in the PR
  body. The gate, plan-gate flags, and escalation all now use the same predicate.
- Sole-source fetch failure had no rule (an auto run could barrel ahead with zero
  requirements). → Collapses to the no-input case in both modes: ask and stop; failed fetches
  recorded as evidence (command + error), so "fetch failed" can't be laziness in disguise.
- state.md template was unwritable at intake (`spar:` had no pre-spar value; Task unknowable;
  append-shaped sections violated the header rule). → `spar: pending`, sanctioned
  placeholders, and an explicit exemption for the two bounded log sections.
- Skipped: effort ceiling on fetch attempts and a definition of "conservative" assumptions —
  judged over-lawyering; the evidence requirement and scope test carry the real weight.

**Full-lifecycle agent** (fixed):
- `rounds=3` with a 5-lens ladder left the loop's exit undefined (kill shot could be squeezed
  out, making convergence unsatisfiable). → Final round is always the kill shot; N−1 most
  valuable lenses run first.
- Verdict semantics were unpinned: cumulative-unresolved verdicts made early exit impossible;
  per-round verdicts let a disputed BLOCKING converge silently. → Verdict contract now spells
  it out: this round's findings + maintained prior findings, conceded and
  nothing-new-to-add disputes excluded, the latter tracked via a `STILL DISPUTED:` channel;
  convergence additionally requires no unresolved BLOCKING disagreement in state.
- Fixed reply-file path made a failed round silently reuse last round's verdict, and the
  `| grep | head -1` capture could SIGPIPE-kill Codex mid-review. → Fresh `mktemp` reply file
  per call, success = non-empty new file + thread event, stream captured to file then parsed.
- Plan template had no test-strategy section though Build and lens 4 referenced one. → Added.
- Dossier-after-CI invalidated the watched green. → Dossier commits before the PR opens.
- Build's "fix the plan first" contradicted the freeze. → Routed through the deviation
  protocol ("the freeze means no *silent* change").
- Integration-branch resolution, mid-build spot-check bounds, ship re-review mechanics
  (resumed session over the fix delta; cap counted per branch): all specified.

**tandem-review adversarial agent** (fixed):
- Base resolution could silently pick `main` when `develop` was the real integration branch;
  scope used `git status` names instead of a working-tree diff, corrupting the pre-existing
  bucket. → Deterministic base resolution (upstream → repo default; multiple candidates =
  ask), scope = `git diff <merge-base>` + untracked listed separately, suspicious scopes
  (empty/one-commit on a long-lived branch) re-verified before "nothing to review".
- The inline safety crib had no success/failure contract (an empty reply could read as
  CLEAN). → Crib hardened: success contract, stderr log, last-line verdict parse with
  missing-verdict=MATERIAL, `--last` prohibition, version preflight.
- Fix-loop caps could be reset by fresh sessions or standalone-then-approved flows; "a caller
  that says so" let any programmatic caller skip the STOP. → Cap counted per feature branch,
  never reset; only the tandem ship phase carries consent; Claude explicitly writes nothing
  on review-only invocations.
- Codex's headline verdict could survive a triage that gutted it, and no-file:line findings
  had no bucket. → Verdict recomputed from confirmed findings only; four exhaustive buckets
  including "unverifiable inference"; coverage spot-check against the files-touched list.
- Description leaks ("second model opinion on these changes" capturing single-function asks).
  → Tightened to "this branch's changes" + explicit NOT for single-function/snippet review.

## 4. Post-fix regression check

A second panel of fresh agents re-ran the highest-risk scenarios against the fixed files.

**Sparring semantics recheck** — failure-ladder recovery, mid-build resume safety, and the
STILL DISPUTED verdict chain all PASSED as unambiguous. Remaining defects found and fixed:
- Converged/deadlocked wasn't exhaustive (a MATERIAL kill shot at the cap fit neither). →
  Classification now happens after arbitration, where the two outcomes ARE exhaustive:
  unresolved BLOCKING disagreement = deadlock, everything else = converged; one kill-shot
  re-run allowed within the cap when accepted findings changed the plan.
- Disagreement G-ids carried no severity, so the "unresolved BLOCKING" test wasn't computable
  from state alone. → Severity added to the G-id template.
- Spot-check rounds had no logging home and broke the "capped" claim on `## Spar rounds`. →
  Logged as `SC<n>` lines; bound restated as max_rounds + one SC per reopened decision.
- `spar: skipped` was an orphan enum value; the solo line was unfillable when no thread ever
  started. → `skipped` removed; thread part made optional.
- Recovery-slot accounting clarified: the cap counts completed review rounds only.

**tandem-review recheck** — dirty-tree scope, failure states, verdict recomputation, and the
no-mutation rule all PASSED. Remaining defects found and fixed:
- The default-branch fallback could still "settle" a main+develop repo, making the ask-rule
  dead code. → Resolution reordered: ambiguity check before any fallback; the default branch
  existing does not settle multiple candidates.
- The fix-cycle cap had no durable store across sessions. → Recorded in `state.md § Ship` in
  tandem context; cycles-used tally stated in every standalone presentation; "keep going"
  buys exactly one cycle.
- A BLOCKING-class unverifiable inference could hide behind a recomputed CLEAN. → Verdict is
  `UNRESOLVED (<severity>-class inference outstanding)` in that case, never plain CLEAN.
- Crib gaps: failed calls don't count as cycles; untracked-file *content* must be read.

## 5. Verdict

Both skills survived two adversarial rounds with all confirmed defects fixed; the Codex CLI
protocol is live-verified end-to-end on 0.146.0. Residual known limitations are listed in the
README. The natural next iteration is field use: the first few real `/tandem` runs will teach
more than a third tabletop round would.
