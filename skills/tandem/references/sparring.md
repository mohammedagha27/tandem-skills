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
## Test strategy        <what proves each requirement; which suites/commands>
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

- **The final round is always the kill shot.** With `max_rounds = N < 5`, run the N−1 most
  valuable lenses first (default order, dropping from the middle what's least contestable for
  this task), kill shot last.
- **Skip** a lens whose territory is already settled (e.g. requirements were exhaustively
  confirmed with the user) — log the skip and reason in `state.md`. Never skip the kill shot.
- **Early exit:** a round returning CLEAN or only-MINOR fast-forwards to the kill shot. A kill
  shot returning CLEAN or only-MINOR converges the loop — provided no unresolved BLOCKING
  disagreement sits in `state.md` (see Convergence below).
- **Cap:** completed review rounds ≤ `max_rounds` (kill shot included). Failed calls and the
  protocol's recovery attempt don't consume rounds; an interrupted lens re-runs.

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
rebuttal is signal) or concede (that's convergence). The verdict contract's `STILL DISPUTED`
channel keeps unresolved arguments tracked without letting them poison every later verdict.

## Arbitration — after every round

For each finding, Claude decides, in `state.md`, one of:

- **Accept** — but first verify it against the actual code/docs; a plausible-sounding finding
  that mis-reads the repo is rejected with the evidence. Then revise `plan.md`.
- **Reject** — with a logged one-line reason. Rejections without reasons are forbidden: they
  rot into "Codex was ignored".
- **Escalate** — for scope-ambiguous, security-sensitive, or destructive calls. Present both
  positions and a recommendation; the user decides.

Append the full critique + your response to `spar-log.md`. Update `state.md`: one summary line
per round (lens, verdict, accepted/rejected/escalated counts) plus any new decisions (D-ids)
and disagreements (G-ids, including everything Codex lists under `STILL DISPUTED`). **Carry
forward through state, never by re-reading the log.**

Don't cave to everything (that defeats the cross-model check) and don't dismiss everything
(that defeats the point). The healthy signature is a mixed record with reasons on both sides.

## Convergence and deadlock

The loop ends when the kill shot has run and been arbitrated (early exit or cap — either way,
kill shot last). One exception: if the kill shot lands MATERIAL+ findings that Claude accepts
(the plan just changed) and unspent rounds remain, one re-run of the kill shot is allowed
within the cap. Then classify — the two outcomes are exhaustive **after arbitration**, because
every finding is by then accepted (folded into the plan), rejected (logged), or escalated:

- **Deadlocked:** an unresolved BLOCKING disagreement stands in `state.md § Disagreements`.
  A legitimate outcome, never papered over.
- **Converged:** everything else — including a MATERIAL kill shot whose findings were all
  accepted or rejected-with-reason. Surviving non-blocking disagreements ride to the Plan
  gate as presentation items, not tie-breaks.
- **The tie-break always goes to the user, in every autonomy mode**, and is presented ONCE,
  merged into the Plan gate: for each contested G-id — Codex's position, Claude's
  counter-position, a recommendation. After the user rules: log the resolution on the G-id,
  update `plan.md`; the round cap stays spent (no further Codex rounds — the dossier notes
  that any post-tie-break revision shipped without re-review).

## Mid-build spot-checks

When Build reopens a decision (broken assumption) and the new approach is materially
different, one spot-check round is allowed: same prompt shape, same verdict contract, resumed
thread if alive, else fresh with a catch-up. Max one per reopened decision; spot-checks don't
count toward `max_rounds` and are logged in `state.md § Spar rounds` as `SC<n>` lines.

## Solo mode (Codex unavailable)

Per the failure ladder in `codex-protocol.md`: tell the user plainly what failed and that the
spar continues single-vendor (weaker — say so), set `spar: solo (degraded round <n>, was
codex thread <id>)` in `state.md` (omit the thread part if no session ever started), and run
the remaining lens ladder using a **fresh
general-purpose subagent per round** as devil's advocate. Solo subagents have no session
memory, so every solo prompt must carry: the `plan.md` path, settled decisions (D-ids), and
previously rejected findings with reasons — or they will re-litigate everything. Same lens
charters, same severity/verdict contract, same cap, same arbitration, same logging. If
subagents are also unavailable, run the ladder yourself in explicit devil's-advocate passes
and mark the dossier accordingly.
