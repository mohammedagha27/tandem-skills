# Sparring — the bounded Claude ↔ Codex argument

Purpose: subject a concrete draft plan to cross-model adversarial pressure until it either
hardens or honestly deadlocks. Codex critiques; Claude arbitrates; the user only enters for
decisions that are genuinely theirs. Mechanics for calling Codex: `codex-protocol.md`.

## Draft first

Codex bites hardest on something concrete. Before round 1, write `plan.md`:

```markdown
# Plan: <task>          _(draft — under sparring)_
## Goal                 <one paragraph, in the project's own terms>
## Requirements         <R1..Rn from state.md, each: confirmed|assumed>
## Approach             <numbered, concrete steps with file paths>
## Key decisions        <the contestable choices, named explicitly — give Codex something to bite>
## Risks / open questions
## Out of scope
```

Name the contestable decisions honestly. A plan that hides its trade-offs gets a useless review.

## The lens ladder

Each round has ONE purpose. Default order:

| # | Lens | The round's question |
|---|---|---|
| 1 | Intent & assumptions | Are we solving the right problem? Which stated/unstated assumptions are wrong? Is there a simpler reframe? |
| 2 | Architecture & approach | Does the design fit this codebase? Integration risks, coupling, better alternatives? |
| 3 | Edge cases & failure modes | Concurrency, partial failure, bad input, security, migrations, data integrity. |
| 4 | Simplification & delivery | What can be cut (YAGNI)? Better sequencing? Is the test strategy adequate? |
| 5 | Kill shot | No lens. "This plan ships tomorrow — make your strongest case it shouldn't." |

Adaptive rules — rounds must earn their cost:

- **Skip** a lens whose territory is already settled (e.g. requirements were exhaustively
  confirmed with the user) — log the skip and reason in `state.md`. Never skip the kill shot.
- **Early exit:** a round returning CLEAN or only-MINOR fast-forwards to the kill shot. A kill
  shot returning CLEAN or only-MINOR converges the loop.
- **Cap:** total rounds ≤ `max_rounds` (kill shot included). If findings are still landing at
  the cap, that's a deadlock, not a failure — see below.

## Prompt shape per round

First round carries context; later rounds carry only the delta (the session remembers the rest):

```
Round 1:  You are an adversarial reviewer sparring over an implementation plan before any
          code exists. Be skeptical and specific — find what breaks, don't be agreeable.
          Read plan.md at <path> and any repo files you need (you are read-only).
          THIS ROUND'S SOLE FOCUS: <lens charter from the table>.
          For each finding: severity tag, one-line concrete fix. <verdict contract>

Round N:  The plan changed since your last look: <2-5 bullet summary of revisions, including
          which of your findings were REJECTED and why>. THIS ROUND'S SOLE FOCUS: <next lens>.
          Re-read plan.md. Do not re-litigate points you already conceded. <verdict contract>
```

Telling Codex what was rejected and why is essential — it can rebut with new evidence (that
rebuttal is signal) or concede (that's convergence).

## Arbitration — after every round

For each finding, Claude decides, in `state.md`, one of:

- **Accept** — but first verify it against the actual code/docs; a plausible-sounding finding
  that mis-reads the repo is rejected with the evidence. Then revise `plan.md`.
- **Reject** — with a logged one-line reason. Rejections without reasons are forbidden: they
  rot into "Codex was ignored".
- **Escalate** — only for scope-changing, security-sensitive, or destructive calls. Present
  both positions and a recommendation; the user decides.

Append the full critique + your response to `spar-log.md`. Update `state.md`: one summary line
per round (lens, verdict, accepted/rejected/escalated counts) plus any new decisions (D-ids)
and disagreements. **Carry forward through state, never by re-reading the log.**

Don't cave to everything (that defeats the cross-model check) and don't dismiss everything
(that defeats the point). The healthy signature is a mixed record with reasons on both sides.

## Convergence and deadlock

- **Converged:** kill shot returns CLEAN/MINOR → proceed to the Plan gate.
- **Deadlocked:** cap hit with unresolved BLOCKING/MATERIAL that Claude disputes → present each
  contested point with Codex's position, Claude's counter-position, and a recommendation. The
  user breaks the tie. A flagged disagreement beats a false "approved" — never fake convergence.
- Surviving disagreements (either kind) are recorded in `state.md § Disagreements` and appear
  in the dossier. They are among the most valuable things this process produces.

## Solo mode (Codex unavailable)

Per the unavailability test in `codex-protocol.md`: tell the user, set `spar: solo` in
`state.md`, and run the same lens ladder using a fresh general-purpose subagent per round as
devil's advocate (fresh = no investment in the plan; instruct it to attack, same severity and
verdict contract). Same cap, same arbitration, same logging. Weaker than a cross-model check —
say so in the dossier — but far better than zero adversarial pressure. If subagents are also
unavailable, run the ladder yourself in explicit devil's-advocate passes and mark the dossier
accordingly.
