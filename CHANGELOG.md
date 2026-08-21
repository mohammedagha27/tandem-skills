# Changelog

Skill versions live in each SKILL.md's `metadata.version`; this file tracks the family.

## 0.2.0 — 2026-08-21

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
