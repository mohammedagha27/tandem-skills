# Intake — from raw input to requirement stubs

Goal: turn whatever the user gave you into a populated `state.md` with sources fetched, repo
context discovered, and requirement stubs ready for the Understand phase. Don't interview the
user here — collect first, ask later, so every question you eventually ask is one only they
can answer.

## 1. Classify the input

The argument can be any mix of:

- **Ticket ID** (`PROJ-123`, `#456`, a tracker URL) — fetch via whatever the session has:
  Linear/Jira/GitHub MCP tools, `gh issue view`, or a URL fetch. Pull title, description,
  acceptance criteria, comments (comments often contain the real requirements), linked issues.
- **Document paths** (`docs/feature.md`, a PRD) — read them fully; note which requirements are
  explicit vs implied.
- **URLs** — fetch; if the fetch fails, record the source as unfetched and ask for a paste.
- **Prose** ("Add bulk export support") — the prose is the source; expect the Understand phase
  to carry more weight.
- **Nothing** — ask one question: "What are we building? A ticket ID, doc, or a sentence all
  work."

Every source gets a line in `state.md § Sources` with its fetch status. An inaccessible source
is never silently dropped: report it, ask for a paste, continue with what exists, and treat
requirements that depended on it as `open`.

## 2. Discover repo context (before forming opinions)

Bound this to what the task touches — it's reconnaissance, not an audit:

- Conventions: `CLAUDE.md`, `CONTRIBUTING`, lint/test configs, how similar features are built
  (find one neighboring example and read it properly).
- Domain language: `CONTEXT.md`, glossaries, ADRs in `docs/adr/` — if they exist, their terms
  are canonical; flag any conflict between the ticket's language and the repo's language as a
  question for Understand.
- The actual code the change lands in: entry points, data flow, existing tests.
- Recent history: `git log --oneline -15` on the touched area — someone may be mid-refactor.

Use subagents for broad sweeps when the repo is large; keep conclusions, not file dumps.

## 3. Produce requirement stubs

Write `state.md` (format: `state.md` reference) with every requirement you can extract, each
tagged `confirmed` / `assumed` / `open` and given an acceptance line ("accept: …") where the
source provides one. Rules of thumb:

- A requirement stated unambiguously by a fetched source: `confirmed`.
- Anything you inferred, defaulted, or read between lines: `assumed`, with the basis recorded.
- Anything with two live readings, or that depends on an unfetched source: `open`.
- Also stub the *non-functional* expectations the repo implies (test coverage norms,
  performance-sensitive paths, security surfaces) — these are the requirements tickets forget.

Then move to Understand: codebase answers what it can; the user answers only what remains.
