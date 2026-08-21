# Tandem — Design Decision Journal

This document records how Tandem was designed: what was studied, what was decided, what was
rejected, and why. It is the durable memory for future maintenance of these skills.

Date: 2026-08-21. Environment at design time: Claude Code with codex-cli 0.146.0
(`model = gpt-5.6-sol` in `~/.codex/config.toml`), macOS.

## 1. The problem

The prior generation of skills — this author's earlier unpublished Codex-review derivatives,
built on Matt Pocock's `grill-me` / `grill-with-docs` (MIT) — solved two failure modes well:

1. Building the wrong thing (fixed by relentlessly interviewing the user).
2. A plan that sounds right but breaks (fixed by a cross-model adversarial review loop with
   OpenAI Codex as a read-only critic).

They stopped at the plan. Everything after — implementation, verification, feature-level review,
PR, CI, documentation — was out of scope, and the two skills duplicated the entire Codex review
"Act 2" verbatim (~90 lines each). There was no requirement intake (tickets, docs, links), no
resumability, no configuration mechanism, and every review round used the same generic prompt,
which made multi-round loops repetitive.

## 2. What was studied

| Source | What it does well | What Tandem takes / leaves |
|---|---|---|
| `grill-me` (Pocock) | One-question-at-a-time interview, recommended answer per question, "explore the codebase instead of asking" | Taken wholesale as the understanding phase's interaction style |
| `grill-with-docs` (Pocock) | Glossary challenge, term sharpening, concrete-scenario stress tests, code cross-reference, lazy doc creation, strict 3-part ADR test | Taken: scenario stress tests, code cross-reference, the ADR restraint test. Left: mandatory CONTEXT.md machinery (folded into intake as "respect existing docs") |
| prior Codex-review derivatives (unpublished) | Verified Codex CLI mechanics (thread resume, sandbox enforcement on resume, stdin EOF hang, timeouts), bounded rounds, deadlock honesty, Claude-as-arbiter, append-only argument log | Taken: all mechanics (re-verified on 0.146.0), arbiter rule, deadlock protocol. Left: monolithic single-file structure, verbatim duplication, binary APPROVED/REVISE verdicts, single repeated review prompt |
| `codex-review` / `codex-build` | Clean-tree gate, temp-file prompt discipline, `-o` file (never parse JSONL for content), bounded fix rounds, human diff gate, background-run banner | Taken: prompt/file discipline, bounded fix loops, verify-yourself rule. `codex-build` (Codex implements) intentionally NOT absorbed — Tandem keeps Claude as the implementer and Codex as the critic; delegated implementation remains a separate concern |
| `superpowers:brainstorming` | Hard gate before implementation, one question per message, 2–3 approaches with recommendation, decompose-before-refine for oversized scope, spec self-review checklist | Taken: gate, question style, approach proposals, scope decomposition, self-review |
| `superpowers:writing-plans` | Zero-context executor assumption, exact paths, no placeholders ("TBD" is a plan failure), type-consistency self-review | Taken: plan quality bar and the no-placeholder rule |
| `superpowers:verification-before-completion` | "No completion claims without fresh verification evidence" | Taken as the ship phase's iron law |
| `handoff` | Compact state for a fresh agent; reference artifacts by path instead of duplicating | Taken as the resumability model: `state.md` is a standing handoff document |
| `superpowers:subagent-driven-development` (Jesse Vincent, MIT; adopted post-publication, see §12) | Zero-context task briefs, fresh implementer subagent per task, reviewer gates, reports on disk | Taken (adapted): brief format, per-task fresh implementers, risk-sized task review. Left: separate progress ledger, five-round fix loops, model-escalation policy, its own final whole-branch review and branch finishing (tandem-review and ship own those) |
| `skill-creator` + `superpowers:writing-skills` | Progressive disclosure (metadata → SKILL.md → references), trigger-focused descriptions that do not summarize workflow (summaries become shortcuts Claude follows instead of reading the skill), token efficiency, test-with-subagents | Followed in the construction of these skills themselves |
| `documentation-writer` (Diátaxis) | Four-quadrant discipline; the dossier is an Explanation-quadrant artifact with Reference elements | Shapes the dossier template |
| codex plugin (`codex-cli-runtime`, `codex-result-handling`; a locally installed Claude Code plugin, not part of this repo) | Severity-ordered findings, preserve evidence boundaries (fact vs inference), never auto-apply review fixes | Taken: severity ordering, evidence-boundary preservation in review output handling |

Attribution note: an early project brief attributed the originals to Andrej Karpathy; the
THIRD-PARTY-NOTICES bundled with the predecessor skills attribute `grill-me`/`grill-with-docs`
to **Matt Pocock** (github.com/mattpocock/skills, MIT). Tandem attributes accordingly.

## 3. Architecture decision: two skills + shared references

Options considered:

- **A. One orchestrator skill with modes.** Lowest duplication, one install. Rejected as the
  *only* skill because the feature-review capability has clear standalone value ("codex review
  this branch") and deserves its own trigger surface; burying it as a mode bloats the
  orchestrator's description and hurts triggering.
- **B. Two complementary skills** — `tandem` (lifecycle orchestrator) and `tandem-review`
  (standalone cross-model feature review). The orchestrator *invokes* `tandem-review` at the
  ship gate instead of duplicating it. **Chosen.**
- **C. Skill family with a shared non-invocable primitives skill.** Rejected: a third unit to
  install and keep in sync buys nothing two well-factored skills don't already provide.

Duplication control: the full Codex CLI protocol lives once, in
`tandem/references/codex-protocol.md`. `tandem-review` reads it from the sibling skill and
carries only a ~10-line inline safety crib (the lines that prevent dangerous or hanging runs)
so a standalone install degrades safely rather than dangerously.

Context control: `tandem/SKILL.md` is a router (~170 lines) — lifecycle map, state contract,
gates, failure ladder. Each phase's playbook is a reference file loaded only when that phase
starts. A resumed session reads `state.md` plus the current phase's playbook, never the
whole history.

## 4. The lifecycle

```
Input → Intake → Understand → Spar (Claude ↔ Codex) → Plan gate →
Build → Ship (verify → tandem-review → dossier → PR → CI)
```

(The dossier commits on the feature branch *before* the PR opens — validation caught that
committing it after a watched CI run silently invalidates the recorded green.)

Changes from the lifecycle proposed in the original project brief:

- "Context discovery" and "requirement understanding" merged into **Intake → Understand**:
  discovery is not a separate pass; every requirement is either answered by the repo/docs or
  asked of the user, in that order (Pocock's rule, generalized).
- "Brainstorming" and "planning" fused into **Spar**: the draft plan *is* the brainstorming
  substrate. Codex critiques a concrete proposal, not vibes — concrete artifacts draw sharper
  criticism. The plan gate is the exit of sparring, not a separate phase.
- **Documentation is generated from state, not from memory**: the dossier is a rendering of
  `state.md` (decisions, disagreements, deviations, verification evidence), which was
  maintained all along — so the last step is cheap and accurate instead of a recall exercise.

## 5. Sparring design (the core improvement)

Binary `VERDICT: APPROVED|REVISE` was too coarse: any nit forced another full round, and
identical prompts made rounds repetitive. Replaced with:

- **Lens ladder** — each round has one purpose: (1) intent & assumptions, (2) architecture &
  approach, (3) edge cases & failure modes, (4) simplification & delivery, (5) kill shot
  (final no-holds-barred attempt to break the plan). Claude may skip a lens whose territory is
  already settled (skip is logged with a reason). The last executed round is always the kill shot.
- **Severity-tagged verdicts** — every finding is `[BLOCKING]`, `[MATERIAL]`, or `[MINOR]`;
  the round verdict is the highest unresolved severity or `CLEAN`. Early exit: a round that
  comes back CLEAN or MINOR-only fast-forwards to the kill shot; a CLEAN/MINOR kill shot
  converges the loop.
- **Claude is the arbiter** — accept (revise plan), reject (with a logged reason), or escalate
  to the user (only for scope-changing / security-sensitive / destructive calls). Disagreements
  that survive are preserved verbatim in state and surface in the dossier.
- **Context carry-forward** — the Codex session is resumed by thread id (Codex keeps its own
  memory); Claude's memory is `state.md` deltas. Full critiques go to an append-only
  `spar-log.md` for the record but are never re-read wholesale.
- **Hard cap** (`max_rounds`, default 5). Cap hit with unresolved BLOCKING = honest deadlock,
  handed to the user. No fake convergence.

## 6. State, resumability, traceability

Single working directory per feature: `.tandem/<slug>/` containing `state.md` (structured,
current-truth only), `plan.md` (living plan), `spar-log.md` (append-only record). `state.md`
carries requirement ids (R1…) with status confirmed/assumed/open; plan tasks and the dossier
reference them, giving cheap requirement traceability and honest confidence tracking.
`/tandem resume` reads `state.md` → jumps to the recorded phase. The `.tandem/` directory is
gitignored by default (the dossier, which is committed, is the durable artifact; state is
working memory).

## 7. Configuration

Precedence: built-in defaults → the active installation's `config.md` (lives beside the
loaded `SKILL.md`; see §13 for why this replaced the original repo-level `.tandem/config.md`) →
invocation arguments (`/tandem rounds=3 review=off …`). Eight keys, all with strong defaults:
`codex=on` (off = fully single-model, added post-audit as the honest privacy/no-Codex switch),
`max_rounds=5`, `codex_review=on`, `execution=auto` (auto|inline|subagents),
`pr=ask` (ask|auto|off), `ci=on`, `docs=on`, `autonomy=guided` (guided|auto). Zero
configuration required for normal use; the whole contract (schema, aliases, validation, path
resolution, the `/tandem config` mode) is defined once in
`skills/tandem/references/config.md`.

## 8. Failure & degradation ladder

Explicit behavior for: inaccessible ticket/doc (mark source unfetched, ask for a paste,
continue with lowered confidence); Codex unavailable (originally an automatic **solo mode** —
superseded by §14's user-owned `codex_failure` policy: ask | stop | Claude fallback critics);
persistent disagreement
(deadlock → user); unrelated test failures (baseline failure snapshot taken before first
change; only deltas are ours); CI failures (same classification); PR creation failure (report,
give the manual command, branch stays pushed); interruption (state.md → resume).

## 9. What was deliberately left out

- **Codex as implementer** (codex-build's role flip). One skill family, one role model:
  Claude implements, Codex critiques. Delegated implementation can be added later as a third
  skill without touching these two.
- **Live doc mutation during the interview** (grill-with-docs' inline CONTEXT.md updates).
  Valuable but orthogonal; Tandem respects existing glossaries/ADRs during intake and offers
  ADRs at the plan gate using Pocock's 3-part test, without owning a glossary lifecycle.
- **More modes.** Only `plan`, `spar`, `resume` (plus default full). "Review only" is the
  second skill, not a mode.

## 10. Verified Codex mechanics (re-verified on codex-cli 0.146.0, 2026-08-21)

- `codex exec` refuses to run outside a trusted directory (a git repo) unless
  `--skip-git-repo-check` is passed — new since the 0.137-era notes. Tandem always runs from
  the target repo root, and the protocol documents the flag for edge cases.
- `codex exec -s read-only --json -o <file> - < prompt-file` works; `thread.started` carries
  the thread id; the final message lands in the `-o` file.
- `codex exec resume <id>` still rejects `-s`; sandbox must be forced with
  `-c sandbox_mode="read-only"` on every resume (the single most important safety line).
- Prompts are passed via stdin from a temp file (`- <"$P"`), which simultaneously avoids
  quoting bugs and the non-TTY stdin-EOF hang.
- 10-minute ceiling per call (`timeout: 600000` on the Bash tool); a tripped ceiling is a
  failed run, surfaced, never silently retried.

## 11. Validation performed

See `docs/VALIDATION.md` for the scenario matrix and findings that fed back into the skills.

## 12. Post-publication addition: adaptive subagent execution (2026-08-21)

The build playbook gained an execution model adapted from Jesse Vincent's
`superpowers:subagent-driven-development` (MIT). Options considered:

- **Vendor the upstream skill wholesale, mandatory for every build.** Rejected: it carries
  its own ledger (`progress.md`), its own per-task and final whole-branch review loops, and
  branch-finishing — duplicating `state.md` and `tandem-review` — plus fork drift against a
  living upstream. Upstream itself routes adaptively; mandating it everywhere would
  contradict its own rules.
- **Detect-and-delegate when superpowers is installed.** Rejected: identical invocations
  would behave differently across machines, and the delegated skill would still own a
  second ledger and final review.
- **Absorb the primitives, adaptively (chosen).** Plans now carry zero-context TASK briefs;
  build classifies inline vs per-task fresh subagents (`execution=` was invocation-only
  here — superseded the same day by §13, which made it a persistent key); workers get brief +
  repo, never
  the conversation; reports live on disk, short statuses return; task review is sized to
  risk (one focused correction, then the deviation protocol); `state.md` stays the only
  ledger and `tandem-review` the only final gate. Not imported: the separate ledger,
  five-round fix loops, model-escalation policy, uniform review ceremony, branch finishing.

## 13. Installation-scoped configuration (2026-08-21)

`.tandem/config.md` (repo-level defaults) was replaced by ONE persistent scope: the active
skill installation — `<TANDEM_SKILL_DIR>/config.md`, resolved as "the directory containing
the SKILL.md that was actually loaded" (works for global, project-level, custom
CLAUDE_SKILLS_DIR, and symlink installs alike; through a symlink the file lands in the clone,
which is one physical file that survives re-linking — this repo gitignores
`skills/*/config.md` so personal defaults never enter the published repo).

Why the move: defaults are a property of how a *user* runs tandem, not of the repos they run
it on; the old location put a preferences file inside every target repo (mutating repos
uninvited, inviting accidental commits) and made two sources of truth once invocation-only
overrides appeared. `execution` was promoted from invocation-only to a normal persistent key
(`auto|inline|subagents`, default `auto`) at the same time, which deleted its special-case
recording rule.

Decisions: exactly one persistent scope (no global-vs-project merging — the loaded
installation wins by definition); `tandem-review` reads the same file via its sibling tandem
directory, never its own; a missing file means built-ins and is only created by an explicit
`/tandem config` save; runtime precedence stays defaults → installation config → invocation
args, with resolved values recorded in `state.md` so resume stays deterministic. The whole
contract lives once in `references/config.md`; SKILL.md, building, state, resume, and
tandem-review all point at it. A `/tandem config` mode (interactive + `show` / `key=value` /
`reset`) edits the file from inside Claude Code and never enters the lifecycle. Migration:
clean replacement (the pre-release `.tandem/config.md` is not read; if one is found, tandem
says so and offers a one-time copy of its valid values) — the project had been public for
hours, not long enough to promise compatibility.

## 14. Codex unavailability policy (2026-08-21)

The automatic "one recovery, then solo" fallback was replaced by a user-owned policy. Two
new config keys: `codex_failure: ask|stop|claude` (default `ask` — silently switching a
cross-model workflow to same-model review is a consent decision, not a degradation detail)
and `claude_fallback_model: inherit|<model id>` (fallback critics only; no hardcoded model
list — validated at dispatch, never silently substituted). Detection unchanged in shape but
reclassified: deterministic failures (missing CLI, bad auth, exhausted quota) are never
retried; transient ones keep the single fresh-session recovery. On unavailability: `ask`
pauses at a safe checkpoint (retry offered only for transient failures; non-interactive runs
stop rather than assume consent), `stop` halts resumably with the failed stage and resume
condition recorded, `claude` enters run-wide fallback mode — fresh "Claude fallback critic"
subagents receive exactly what Codex would have (plan/state paths, lens charter, delta,
dispositions — never the raw conversation), same contracts and caps, findings still verified
by the orchestrator, and later stages never re-ask. Labeling is load-bearing: fallback output
is never described as Codex review or cross-model consensus, and the dossier and PR disclose
material same-model reviews. `codex: off` stays a choice, not a failure — it never triggers
the policy and remains distinguishable in state (`solo (by config)` vs `claude-fallback`).
Kept separate by design: implementation subagents (`execution`) — different system, own
model behavior, never reused to review their own work.

## 15. Cross-pollination pass (2026-08-21)

Two research agents mined the superpowers family, the grill-me lineage (including Pocock's
CURRENT skills — he refactored to a frontier-batching `grilling` primitive and a separate
`domain-modeling` skill, validating §9's glossary decision), and the codex plugin's GPT-5.x
prompting guidance. Adopted: systematic-debugging's root-cause-before-fix method plus the
"three failed fixes = a wrong decision" circuit breaker (routed into the deviation protocol —
the one whole discipline tandem lacked); native-worktree-tool preference with check-ignore
and end-of-life mechanics; a ship-phase R-id checklist, a plan-draft R-id→TASK coverage
self-check, and red-green verification for behavior-pinning tests; XML block-structured
spar/review prompts with grounding rules (OBSERVED|INFERRED labeling — previously only the
review asked for it), a dig-deeper nudge, and a follow-through policy (live-verified on
codex-cli 0.149.0: planted contradiction caught, labels followed, verdict contract exact);
dependency-frontier question batching replacing one-question-at-a-time (Pocock's own
evolution; also removes an inconsistency with config mode's tabbed dialogs) plus the
scenario-stress-test mechanism §2 claimed but never shipped; restored predecessor protocol
facts (0.130 floor, why `-m` pinning 400s); rejected-alternatives named per key decision;
the letter=spirit clause; severity-ordered per-fix application in the review loop (user's
call over a weak-adopt recommendation). Skipped: full TDD iron law, rationalization tables,
bite-sized checkbox plans, parallel implementers, domain-modeling machinery — each conflicts
with a documented tandem decision.

## 16. Deprecation convention (adopted 2026-08-21, applied as needed)

When a config key, mode, or skill must break compatibility: keep the old name recognized for
one release with a `[DEPRECATED — use <new>]` warning at resolution time (warn once per run,
never guess semantics); mark the replacement in the description/docs the same way ecc does
("[DEPRECATED - use X] … do not invoke; route to X"); record the migration in CHANGELOG.md;
and remove the shim in the following release. Never let two live mechanisms coexist without
a dated removal plan — that rule already killed `.tandem/config.md` (§13).
