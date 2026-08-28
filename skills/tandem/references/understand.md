# Understand — from requirement stubs to a resolved decision map

Resolve every requirement to **confirmed** (the user said so, or the source says so
unambiguously), **assumed** (you chose a reading — record it), or **open**. The order of
authority: the codebase and docs answer first; the user answers only what they alone can.
(Interview devices adapted from Chase AI's claudex-loop and Matt Pocock's grilling discipline —
see THIRD-PARTY-NOTICES.)

## Step 1 — the Assumptions Ledger, once

Before asking anything, present everything intake resolved on its own — every `assumed` R-id
and every inferred convention — as ONE numbered batch, each with its source (file path, doc,
research finding): "confirm or correct in one pass; anything unmarked I treat as confirmed."
It is a prose batch answered in one reply, and it gets its own turn BEFORE the frontier —
never drip assumptions as individual questions, and never merge the ledger into the question
round. Confirmed entries become `confirmed` R-ids; corrections that open real questions join
the decision map. This is the single biggest time-save over a naive interview.

## Step 2 — the Decision Map

Lay out the genuinely open decisions in two tiers and re-print the map (checkboxes ticked) at
each round so the user sees convergence:

- **Load-bearing** — a wrong answer costs a migration, a rewrite, a security hole, or user
  trust (schema, auth, data model, concurrency, money, public API). Asked, one frontier round
  at a time.
- **Cosmetic** — renameable, refactorable, swappable. Batched as recommendations with a
  one-line rationale each; the user vetoes by exception, silence = accepted.

Scale it to the task: zero load-bearing decisions → the map is one sentence and the plan gate
is one paragraph. Ceremony must earn its cost.

## Step 3 — ask the frontier

Every load-bearing question whose prerequisites are already settled goes out in one round,
each in this shape — **the question · why it matters · your committed recommendation · what
breaks if we guess wrong**. A question whose "if we guess wrong" line comes out weak isn't
load-bearing: demote it to the cosmetic batch. A question depending on an answer still open
this round waits; a running exploration blocks only its downstream questions. When a boundary
is fuzzy, pose a concrete scenario ("a user deletes the org mid-export — what should happen?")
instead of an abstract question.

Escape hatch — offer it explicitly when the load-bearing tier exceeds ~8 questions:
**"accept all remaining recommendations"** locks every open decision at its recommended answer
and records each as `assumed (accepted recommendation)`.

Present option-shaped questions through the harness's interactive question tool
(`AskUserQuestion` in Claude Code: one tab per frontier question, ≤4 per dialog, recommended
option first), never as prose the user has to type answers to. The ledger (Step 1) is the one
exception — it's a confirm-or-correct batch, not a pick-list.

## The scope test (one definition, used everywhere)

A requirement is *scope-ambiguous* when two reasonable readings would deliver different
things — a different deliverable, different surfaces touched, a different acceptance line.
"Make search better" is scope-ambiguous (which search? better how?); "which HTTP client for
the fetch" is not. Scope-ambiguous opens go to the user in **every** autonomy mode and are never
converted to assumptions. In `autonomy=auto`, other opens may become assumptions — each
conversion records its basis and `scope: no` in `state.md`, and every live assumption is
surfaced again at the plan gate and in the PR body. The plan gate, escalation, and
`gate_timeout` all reference this definition; don't restate it.

**Gate:** do not start sparring while a scope-ambiguous requirement is still open.
