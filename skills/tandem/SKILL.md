---
name: tandem
description: 'Feature lifecycle with a cross-model sparring partner. Use when the user invokes /tandem, gives a ticket ID (PROJ-123), a requirement doc, links, or a feature request and wants it taken from raw input to understood, planned, implemented, reviewed, and documented — with OpenAI Codex adversarially hardening the plan before any code. Also use when the user says "plan this with codex", "spar with codex", "build this feature properly", "take this ticket end to end", or wants to resume interrupted tandem work. Modes: plan (stop after the plan gate), spar (stop after the sparring loop), resume. NOT for reviewing an existing branch (use tandem-review), NOT for trivial edits a single commit would cover, and NOT for reviewing already-written code.'
---

# Tandem — Build Features With a Sparring Partner

Claude owns the work; Codex attacks it. You take any input — a ticket, a doc, a sentence — and
drive it through: **Intake → Understand → Spar → Plan gate → Build → Ship → Dossier**. Codex is
a read-only critic at two points (plan sparring, pre-PR feature review) and never writes a file.
Claude is the final arbiter of every critique: incorporate what's right, reject what's wrong
with a logged reason, and escalate to the user only what is genuinely theirs to decide.

Two artifacts outlive the run: the shipped change, and a **dossier** — durable engineering
documentation of what was decided and why. Neither is a chat transcript.

## Working state (read this contract first)

All working memory lives in `.tandem/<slug>/` at the repo root (`<slug>` = short kebab name for
the feature; add it to `.gitignore` if not already ignored):

| File | Role |
|---|---|
| `state.md` | The single source of truth: phase, config, requirements, decisions, disagreements, deviations, verification evidence. Update it **as things happen**, not at phase ends. |
| `plan.md` | The living plan. Draft during Spar, frozen at the Plan gate, annotated with deviations during Build. |
| `spar-log.md` | Append-only record of every Codex critique and Claude response. Written once, never re-read wholesale — carry context forward through `state.md` only. |

The format for `state.md` is in `references/state.md` — read it before creating the file.
**Why this matters:** the state file is what makes the workflow resumable, keeps a multi-round
cross-model argument from flooding context, and is the raw material the dossier is rendered
from. A stale state file silently breaks all three.

## Configuration

Precedence: defaults → `.tandem/config.md` (repo-level `key: value` lines) → invocation args
(e.g. `/tandem PROJ-123 rounds=3 review=off autonomy=auto`). Echo the resolved values once at
kickoff.

| Key | Default | Meaning |
|---|---|---|
| `max_rounds` | `5` | Hard cap on sparring rounds. The loop always terminates here. |
| `codex_review` | `on` | Pre-PR feature-level review via the `tandem-review` skill. |
| `pr` | `ask` | `ask` = confirm before opening a PR; `auto` = open it; `off` = stop at a pushed branch. |
| `ci` | `on` | Monitor CI checks after the PR opens. |
| `docs` | `on` | Generate and commit the dossier. |
| `autonomy` | `guided` | `guided` = pause at gates (questions, plan sign-off). `auto` = proceed through normal gates; still always ask for destructive, security-sensitive, or scope-changing decisions. |

## Modes

- `/tandem <input>` — full lifecycle.
- `/tandem plan <input>` — stop after the Plan gate (plan + dossier-of-plan, no code).
- `/tandem spar <input|path-to-plan>` — run only the sparring loop on a plan (draft one from the
  input if none exists), then stop.
- `/tandem resume [slug]` — read `.tandem/<slug>/state.md` (if no slug, list `.tandem/*/` and
  ask) and continue from the recorded phase. Trust the state file over memory of any prior
  session; verify its `phase` claim against reality (does the branch exist? do the commits?)
  before continuing.

## The lifecycle

Each phase has a playbook in `references/`. Load the playbook **when the phase starts**, not
before — that's what keeps this skill cheap to run.

### 1. Intake — `references/intake.md`
Parse the input (ticket ID, doc, links, prose, or a mix), fetch what's fetchable, discover the
repo context, and produce the first `state.md` with requirement stubs. An inaccessible source
is reported and worked around, never silently dropped.

### 2. Understand
Resolve every requirement to **confirmed** (user said so, or the source says so unambiguously),
**assumed** (you chose a reading — record it), or **open**. The order of authority: the
codebase and docs answer first; the user answers only what they alone can. Interview style when
you do ask: one question per message, your recommended answer attached, walking each branch of
the decision tree until resolved (this is Matt Pocock's `grill-me` discipline). In
`autonomy=auto`, convert non-critical opens into explicit assumptions instead of blocking —
but ambiguity about *scope* always goes to the user.

**Gate:** do not start sparring while a requirement that changes the plan's shape is still open.

### 3. Spar — `references/sparring.md` + `references/codex-protocol.md`
Draft `plan.md`, then run the bounded Claude ↔ Codex argument: purposeful rounds (assumptions →
architecture → edge cases → simplification → kill shot), severity-tagged findings, early exit
when rounds stop earning their cost. Codex unavailable? The playbook's solo-mode fallback
applies — never skip adversarial pressure entirely.

### 4. Plan gate
Present the hardened plan: goal, approach, key decisions with rationale, surviving
disagreements, risks, out-of-scope. In `guided`, wait for approval; in `auto`, proceed unless
the plan contains flagged decisions (destructive, security-sensitive, scope-changing) — those
always wait. Freeze `plan.md`. If Pocock's ADR test applies to any decision (hard to reverse
AND surprising without context AND a real trade-off), offer an ADR.

### 5. Build — `references/building.md`
Implement the frozen plan on a feature branch: baseline-failure snapshot first, small verified
increments, deviations logged and reconciled (a wrong plan gets *updated*, never silently
abandoned). Discovering a broken assumption mid-build reopens the relevant decision — briefly,
with the user if it's theirs.

### 6. Ship — `references/shipping.md`
Fresh full verification (evidence before claims — no output, no "passes"), then if
`codex_review=on` invoke the **tandem-review** skill on the whole feature branch (not the last
diff), triage its findings, fix what's real, rerun verification. Then PR per `pr`, CI per `ci`,
classifying failures as ours vs pre-existing via the baseline snapshot.

### 7. Dossier — `references/dossier.md`
Render `state.md` into a durable engineering document (problem, requirements, decisions,
disagreements, architecture, verification, limitations, follow-ups), save it where the repo
keeps docs, commit it. This is project memory for humans and future agents — not a transcript.

**Definition of done:** verification green (or failures proven pre-existing and reported),
review findings triaged, PR opened and CI green/triaged (per config), dossier committed,
`state.md` phase set to `done` with a closing summary.

## Failure ladder

| Situation | Behavior |
|---|---|
| Ticket/doc/link inaccessible | Say so, ask for a paste, mark the source unfetched in `state.md`, continue with what exists |
| Requirements stay ambiguous | `guided`: keep interviewing. `auto`: assume conservatively + record; scope ambiguity always asks |
| Codex CLI missing/unauthenticated/timing out | Solo mode (see sparring playbook); record the degradation in state and dossier |
| Codex and Claude deadlock at the round cap | Present both positions honestly; the user breaks the tie. Never fake convergence |
| Tests fail before any change | Baseline snapshot; only *new* failures block the ship |
| Implementation exposes a bad assumption | Reopen the decision, update plan + state, continue |
| Context getting heavy | Re-read `state.md` + current playbook only; never re-read spar-log or old diffs |
| PR creation / CI access fails | Report the exact error, give the manual command, leave the branch pushed |
| User interrupts | State is already on disk; `/tandem resume` continues |

## Hard rules

- Codex is read-only in every interaction this skill makes. No exceptions.
- Every Codex loop is bounded and terminates. No unbounded ping-pong.
- Claude never outsources judgment: every accepted finding is verified, every rejected finding
  gets a logged reason, and surviving disagreements are preserved — not smoothed over.
- No implementation before the Plan gate. No completion claims without fresh verification
  evidence in the current message.
- Commits, pushes, PRs: only from Claude, and PRs only per the `pr` config.
- Update `state.md` continuously. If you notice it's stale, fix it before doing anything else.
