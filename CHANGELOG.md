# Changelog

Skill versions live in each SKILL.md's `metadata.version`; this file tracks the family.

## 0.3.0 — 2026-08-28

Read-only audit (skill-reviewer roles, 18 fresh trigger evals, 5 behavioral evals incl. real
`config show` execution) → all findings fixed:
- `research` becomes the twelfth config key (it was an invocation arg the contract had to
  reject); schema table is the single key enumeration; echo/state/tabs follow schema order
- Understand and Plan gate moved out of SKILL.md into `references/understand.md` and
  `references/plan-gate.md` (router back to ~215 lines); autonomy-vs-gate_timeout split
  stated; scope-ambiguous timed-out item parks the WHOLE gate; timeout detection defined
- Fit check in Modes (DO-NOT-TRIGGER inputs decline in one line); `review` first token
  delegates to tandem-review; `resume` with no state reports and stops
- Intake: question budget corrected; skill inventory scan install-relative and confined to
  the research gate; duplicate invocation keys last-wins with a warning
- Descriptions rewritten from an 18-query panel (repo prerequisite, review verbs, config and
  spar natural-language triggers, CV/product exclusions); `source` moved under `metadata`
- `codex_call.sh`: verdict restricted to contract values + VERDICT_VALID, last non-empty
  line, binary-missing = deterministic, CODEX_VERSION echoed
- Dedup: precedence/scope-test/version-claim restatements replaced with pointers; worktree-safe
  exclude path; evals 4/6 corrected and re-sorted; tandem-review shows the merge-base command
  and links the single-model mechanics
- Versions now bump on every behavioral change (the installed copy had drifted 3 files behind
  the repo while both said 0.2.0)

## 0.2.0 — 2026-08-21

- Interview upgrades adapted from Chase AI's claudex-loop (MIT): batch-confirmed Assumptions
  Ledger, why-it-matters/recommendation/if-we-guess-wrong question format with cosmetic
  demotion and an accept-all escape hatch, visible decision map, none/web/deep research
  gate, skill-inventory → optional plan `## Toolchain`; README gains a Receipts section

- Attribution corrected: the inherited Codex CLI critic mechanics are Chase AI's
  `grill-me-codex` / `grill-with-docs-codex` (MIT; now `chaseai-yt/claudex-loop`), not this
  project's own earlier work — THIRD-PARTY-NOTICES, README, and DESIGN updated

- `codex: off` — true single-model opt-out (privacy switch; sparring, spot-checks, and
  review all honor it)
- Installation-scoped configuration: `config.md` beside the active skill installation,
  managed by the new `/tandem config` mode (tabbed pickers; show / key=value / reset);
  `.tandem/config.md` retired (not read; one-time copy offered)
- Adaptive subagent execution in Build (`execution: auto|inline|subagents`): zero-context
  task briefs, fresh implementer per task, risk-sized task review
- `codex_failure: ask|stop|claude` + `claude_fallback_model`: user-owned policy for Codex
  unavailability; labeled "Claude fallback critic", never presented as cross-model
- Trust boundaries (prompt-injection posture) at intake, in critic prompts, and on replies
- XML block-structured Codex prompts with OBSERVED|INFERRED grounding, dig-deeper, and
  follow-through (live-verified on codex-cli 0.149.0); frontier-batched interviewing;
  root-cause debugging discipline; worktree correctness; R-id coverage checklists;
  red-green test rule; subagent dispatch discipline
- Bundled `scripts/codex_call.sh` as the preferred call path (prose protocol remains the
  fallback); `version` metadata + this changelog

## 0.1.0 — 2026-08-21

- Initial public release: `/tandem` lifecycle orchestrator (intake → understand → spar →
  plan gate → build → ship → dossier) and `/tandem-review` whole-branch cross-model review,
  with the verified Codex CLI protocol, state-based resumability, and severity-tagged
  sparring. Published after an independent pre-publication audit (docs/VALIDATION.md).
