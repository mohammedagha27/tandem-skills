# Dossier — durable engineering documentation

The dossier turns the run's reasoning into project memory that stays useful after everyone —
human and model — has forgotten this session. It is an *explanation* document (in Diátaxis
terms) with reference elements. It is rendered **from `state.md` + `plan.md` + the final
diff**, not from conversational memory, and it is explicitly NOT a transcript: no round-by-round
blow-by-blow, no quoted AI dialogue. Reasoning, distilled.

## Location & naming

Follow the repo's existing convention if one exists (`docs/features/`, `docs/design/`,
`docs/adr/` siblings…). Otherwise create `docs/features/` and write
`YYYY-MM-DD-<slug>.md`. Commit it on the feature branch so it rides the PR.

## Template

```markdown
# <Feature name>

_<one-line what-and-why>. Shipped <date>, PR <link>. Built with tandem (Claude + Codex spar)._

## Problem
<the original problem in the project's terms — not the ticket text verbatim>

## Requirements
<from state R-ids: what was required, what was ASSUMED (call these out — they're the
land mines for future readers), acceptance criteria>

## Approach
<final architecture/approach as built, 1-3 paragraphs + key files/components table>

## Decisions
<each D-id worth remembering: the choice, the why, the rejected alternative.
Only decisions that pass "would a future reader wonder about this?">

## Challenged & contested
<the G-ids: where the models disagreed and it mattered — each side's position and how it
resolved. Where sparring materially changed the plan, say what changed. If sparring ran
solo (no Codex), say so.>

## Edge cases handled
<the ones that cost thought, with pointers to their tests>

## Verification
<what was run, results, baseline/pre-existing failures noted>

## Known limitations & follow-ups
<honest list; include review findings consciously deferred>
```

## Rules

- Every claim traceable to state/plan/diff — if it's not in an artifact, don't remember it
  into the dossier.
- Skip empty sections rather than padding them ("no contested decisions" is one line).
- Plain, human prose. No AI-conversation framing ("Codex then suggested…") beyond the
  contested-decisions section where attribution *is* the content.
- Keep it under ~2 pages. The dossier competes for future context windows; earn every line.
- If an ADR was created at the plan gate, the dossier links it instead of duplicating it.

After committing: set `state.md` phase to `done` with a closing summary line. The `.tandem/`
working directory can be deleted by the user at any time — everything durable now lives in
git, the PR, and the dossier.
