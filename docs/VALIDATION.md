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

| Scenario (from the original project brief) | Agent focus | Outcome |
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
  `config.md`). → Specified at the time as: ignore `.tandem/*/` (state dirs), keep
  `.tandem/config.md`. (Since superseded — round 6 moved persistent config out of `.tandem/`
  entirely.)
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

## 5. Round 3 — independent pre-publication audit (second session, 2026-08-21)

A separate session with no authoring context audited the repo as if publishing it that day,
then validated its own changes the same way rounds 1–2 were validated.

- **Fresh external review** (no-context agent, whole repo): rated internal consistency across
  all files as excellent; found one blocker — a README sentence implying `codex_review: off`
  was a privacy switch (it only skips the pre-PR gate; sparring still calls Codex). → Fixed
  properly with the `codex: on|off` knob (a true single-model opt-out) and an honest README
  privacy section.
- **Trigger panel re-run** (12 queries, 6 stored + 6 new near-misses, judged against
  descriptions only): 11/12. The miss — single-FILE codex requests fell between the
  "snippet" exclusion and branch scope. → tandem-review exclusion now reads "single-file,
  single-function, or snippet (branch/feature scope only)"; tandem's description now signals
  the solo fallback ("still applies when Codex is unavailable or unwanted"). 4 of the 6 new
  queries added to `trigger_evals`.
- **Adversarial tabletop of the new paths** (codex=off lifecycle, trust boundaries,
  fresh→resume→failure→recovery, non-GitHub ship): trust-boundary and failure-ladder walks
  CLEAN; 9 findings fixed — undefined `$P2` in the resume snippet; the protocol assumed shell
  variables survive across tool calls (they don't — rounds are now self-contained invocations
  that print what later calls need); mid-build spot-checks and standalone tandem-review both
  leaked Codex invocations past `codex: off`; by-config solo was lumped into degradation
  framing; the dossier header hardcoded "Claude + Codex spar"; the self-review pass had no
  output contract ("looks fine" satisfied it); CI watching was structurally GitHub-only and
  silent about it; MR templates weren't looked up on GitLab.
- **Live re-test via the original implementing session** (codex-cli 0.146.0): resume reliably
  writes the `-o` reply file and does emit `thread.started`; the relaxed resume contract
  (non-empty fresh reply, no event required) confirmed safe. New live finding encoded: the
  JSONL stream of a fully successful run can contain cosmetic `"type":"error"` events — the
  success contract is the only failure test.
- Publication scans (working tree + full git history): no secrets, no company data, no
  private URLs or local paths, no *unintentional* personal data. Intentional author
  identifiers remain by design (license copyright, clone URL, git commit authorship) — kept
  as an explicit pre-publish decision for the author. Quoted upstream Pocock license verified
  verbatim against source.

Method limitation, stated plainly: rounds 1–3 are live protocol tests plus adversarial
tabletop walkthroughs. The scenario evals in `evals/evals.json` are expectations, not
executable fixtures — there are no committed assertions, mock-Codex fixtures, or baseline
runs yet, so this record demonstrates *coherence under adversarial reading and a working CLI
protocol*, not measured outcome improvement. A fixture-based harness (including a mock codex
executable that records whether it was called) is the highest-value next investment.

## 6. Round 4 — Codex counter-audit triage (2026-08-21)

An independent Codex-side audit (run internally; the full report was removed from the repo
after resolution) reached NOT READY TO PUBLISH with
five blockers. Each finding was verified against the files before acting — the same
arbitration rule the skills impose on their own reviews.

**Confirmed and fixed:**
- `codex=off` passed as an invocation arg lands in `state.md`, but tandem-review only honored
  `.tandem/config.md` → reviewer now honors the run's `state.md` config as authoritative, and
  the ship playbook passes the resolved config explicitly.
- README privacy framing ("must not leave your machine") overpromised → now explicit that
  `codex: off` is an OpenAI opt-out, not a fully-local mode; Claude Code still processes the
  repo through Anthropic.
- Base resolution preferred "the branch's configured upstream", which after `push -u` is
  `origin/<same-branch>` → empty scope. Precedence is now: user-supplied → tandem state
  `base:` → PR/MR target → ambiguity check → unambiguous default branch; tracking upstreams
  are explicitly banned as bases.
- Build had no clean-tree gate → new step 0: classify the tree; unrelated dirty work always
  asks (stash / isolated worktree / bless named files), in every autonomy mode.
- Adopted P1/P2 items: round-1 spar prompt now hands Codex `state.md` (not just the plan);
  out-of-focus BLOCKING findings must still be reported; re-review deltas carry prior-finding
  dispositions; terminal failures (missing binary, bad auth) skip the recovery attempt;
  scratch files are cleaned up after each round and Codex's own session retention is
  disclosed; config values are validated (warn + default); state dirs prefer
  `.git/info/exclude` over editing the user's `.gitignore`; the "healthy mixed record" line
  no longer implies a target accept/reject ratio.
- Validation overstatements corrected (this document): personal-data claim scoped to
  *unintentional* data; trigger-eval counts clarified; the fixtureless-eval limitation stated
  above.

**Rejected, with reasons:**
- Wholesale protocol redesign (TANDEM-CRITIC/1 wire format, NEXT-token semantics, dropping
  the lens ladder and kill shot, deleting spar-log, delegating PR/CI to host skills): the
  current contract is live-verified on the actual CLI; the replacement is unproven against
  real Codex behavior, the kill shot and ladder are deliberate anti-laziness bounds that
  already adapt (skip + early exit), spar-log is the bounded audit trail that keeps state.md
  small, and delegating lifecycle stages to Superpowers-style skills would break the
  portability requirement that tandem work without them. Its best ideas (state-aware round-1
  prompt, dispositions in deltas, out-of-focus blocker rule, CLEAN-is-valid framing) were
  taken piecemeal instead.
- "Fixture-based evals as a publication blocker": downgraded to the top follow-up. Prompt
  skills routinely publish with scenario evals; the honest fix is not overclaiming (done),
  not blocking publication on a test harness.
- Requirement delivery-status dimension (`planned|implemented|verified` per R-id): plan
  steps already reference R-ids and `§ Build → Done` tracks steps; a second status dimension
  is bureaucracy ahead of field evidence.

## 7. Round 5 — adaptive subagent execution (2026-08-21)

The build playbook's new execution model (DESIGN §12, adapted from superpowers
`subagent-driven-development`) got the same treatment: an adversarial tabletop by a fresh
agent (6 walks: subagent happy path, blocked worker, inline small build, override/config
interactions, cross-file consistency, trust/safety). Inline and cross-file walks came back
clean; 11 findings were fixed:

- A forced `execution=` override was lost if the run was interrupted between plan gate and
  build start → now recorded on state's `config:` line at kickoff.
- The worktree note sat after Setup, so a literal executor branched and baselined in the
  dirty main checkout first — and the gate's wording made the *unrelated work* move while
  the note moved the *build* → worktree creation is now Setup step 1, before branch and
  baseline; the build moves, the user's work stays; `.tandem/` stays in the main checkout,
  referenced absolutely.
- Worker reports had no consumer ("never take the report's word" let a literal reader never
  open it) → step 3 reads the report first; noted deviations land in state before the code
  is judged.
- Nothing forbade the worker committing → the brief contract now ends with: no commit, no
  push, no state.md — the orchestrator owns git and the ledger.
- A blocked dispatch's half-finished diff had no cleanup rule → inspect, salvage into the
  revised brief, discard the rest; never dispatch onto a dirty tree.
- Task-review findings had no ledger slot and no assigned fixer → `state.md § Build → Task
  reviews` added; orchestrator implements corrections (re-dispatch only for task-sized
  fixes).
- Batching had no naming or bound ("declare everything tiny" shortcut) and parallel dispatch
  created commit-scoping hazards → combined-brief naming (`TASK-<a>+<b>`), "minutes each,
  not real tasks", and dispatches are now strictly sequential.
- Classification left an awkward middle undefined → tie-break: ≥3 independent tasks or one
  large-diff task → subagents; else inline; reason always recorded.
- Risk self-certification softened: "when unsure whether a task is mechanical, it isn't —
  review it."
- Stale references fixed ("plan step" → task; the working-state contract now mentions
  `briefs/` and `reports/` as regenerable non-ledger files).

## 8. Round 6 — installation-scoped configuration (2026-08-21)

`.tandem/config.md` was replaced by one installation-scoped `config.md` plus a
`/tandem config` mode (DESIGN §13; contract in `references/config.md`). Validation actually
executed:

- **Live install tests** (isolated clone, custom `CLAUDE_SKILLS_DIR`): symlink install
  resolves to one physical file through the link (`os.path.realpath` equality asserted);
  re-running `install.sh` over an existing `config.md` preserves it and reports the path; a
  fresh install reports "built-ins in use"; the repo's gitignore keeps `skills/*/config.md`
  invisible to git. All passed.
- **Adversarial tabletop** (fresh agent, 10 walks covering the acceptance criteria:
  interactive/show/assignment/reset, tracked-file and read-only installs, full-run
  resolution + resume, legacy file, tandem-review standalone with `codex: off`, cross-file
  sweep): 8 walks clean, no blockers, 8 findings fixed —
  invalid values now drop to the next-lower precedence layer instead of jumping to built-ins
  (a garbage invocation arg can no longer defeat a valid installation setting); intake
  explicitly resolves config when writing state's `config:` line (template values are never
  copied); `reset` with no file writes nothing; the legacy `.tandem/config.md` check got a
  trigger point (intake repo discovery); tracked-file writes now require explicit
  confirmation, and the tracked/read-only guards are scoped to write operations only;
  pre-existing invalid lines are preserved-and-warned during unrelated edits; a declined
  interactive session exits without writing; tandem-review says so when no sibling tandem
  installation (and hence no config) exists; stale "forced by invocation" phrasing and two
  since-superseded doc-record lines were marked or fixed.
- **Sweep:** no live skill instruction creates or reads `.tandem/config.md` as preferences
  (only the explicit not-read legacy note); state's `config:` template line matches the
  8-key schema exactly; all cross-file pointers resolve.

Not executed (honest limits): no end-to-end interactive `/tandem config` session with a real
user, and the trigger panel was not re-run for the new description clause — the config-mode
trigger queries were added to `trigger_evals` for the next panel.

## 9. Verdict

Both skills survived two authoring-time adversarial rounds, an independent second-session
audit, and a Codex counter-audit, with all confirmed defects fixed; the Codex CLI protocol is
live-verified end-to-end on 0.146.0. Residual known limitations are listed in the README and
in round 3's method note. The natural next iteration is field use plus a fixture-based eval
harness: the first few real `/tandem` runs will teach more than a fifth tabletop round would.
