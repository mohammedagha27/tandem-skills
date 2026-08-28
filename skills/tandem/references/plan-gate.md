# Plan gate — the user signs off the hardened plan

Present the hardened plan in one interaction: goal, approach, key decisions with rationale,
surviving disagreements **including any deadlock tie-break**, live assumptions, risks,
out-of-scope. Use the interactive question tool for the approval and each tie-break
(recommended option first). Scale it: a plan with zero load-bearing decisions gets a
one-paragraph gate.

**Who decides what.** `autonomy` decides whether to *ask*: `guided` waits for approval;
`auto` proceeds unless the presentation carries flagged items — destructive, security-sensitive,
scope-ambiguous (per the scope test in `understand.md`), or a deadlock tie-break — which
always ask, in every mode. `gate_timeout` decides what happens when an ask *gets no answer*.
The two are independent: a deadlock always asks; whether an unanswered deadlock proceeds
provisionally is `gate_timeout`'s call.

**Freeze** `plan.md` on approval (header: `_(frozen at plan gate, <date>)_`). If Pocock's ADR
test applies to any decision (hard to reverse AND surprising without context AND a real
trade-off), offer an ADR — use the repo's existing ADR format if one exists, else a short
Context/Decision/Consequences note in `docs/adr/`.

## Gate timeout

"No answer" means: the interactive question tool returned its own timeout, or there is no
question channel at all (headless/CI run, no interactive tool) — in which case it's an
immediate no-answer, not a wait. One unanswered conversational turn is not a timeout.
Overnight autonomous runs hit this structurally. Then `gate_timeout` (contract in
`config.md`) decides:

- **`wait`** (default): park the run resumably — record the open question(s) in `§ Next` and
  stop; `/tandem resume` re-presents the gate.
- **`proceed`**: adopt the RECOMMENDED option for each timed-out choice and mark it
  **provisional** — the mark rides the plan's freeze header, the decision's state entry
  (`[PROVISIONAL — gate timeout <date>]`), the dossier's contested section, and the PR body's
  ⚠ section; any PR opens as a DRAFT while provisional items exist and becomes ready-for-review
  only when each is explicitly confirmed; re-present them at every later user touchpoint and
  notify the user they're pending. What `proceed` never crosses: scope-ambiguous requirements,
  destructive or irreversible actions, and `codex_failure: ask` pauses. **If any timed-out item
  is in that never-cross set, the ENTIRE gate resolves as `wait`** — record the other
  recommendations in `§ Next` as pending-provisional and stop; there is no partial freeze,
  because building around a scope guess is building on a guess.

The rationale that makes provisional progress safe: everything between the plan gate and the
PR is branch-local and reversible.
