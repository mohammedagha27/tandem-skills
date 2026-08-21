# Tandem

Personal Claude Code skills for building features with a cross-model sparring partner.
Claude does the work; OpenAI Codex attacks it at the two points where a second model earns
its keep: before any code exists (plan sparring) and before the PR opens (whole-feature
review). Codex is read-only at all times.

## The two skills

**`/tandem`** — the lifecycle orchestrator. Give it a ticket ID, a requirements doc, some
links, or a plain sentence:

```
/tandem PROJ-123
/tandem Implement the requirements in docs/feature.md
/tandem Add bulk export support
```

It runs: intake (fetch sources, discover repo context) → understand (codebase answers first,
you answer only what it can't) → spar (a bounded Claude ↔ Codex argument over a draft plan,
each round with its own purpose) → plan gate (you sign off) → build (frozen plan, baseline
test snapshot, logged deviations) → ship (verify, cross-model feature review, PR, CI watch) →
dossier (a short engineering document committed with the change, so the reasoning survives
the session).

Modes: `/tandem plan …` stops at the approved plan. `/tandem spar …` runs only the sparring
loop. `/tandem resume` picks up interrupted work from its state file.

**`/tandem-review`** — standalone cross-model review of a whole feature branch (merge-base to
HEAD plus uncommitted work, not just the last diff). Claude verifies every Codex finding
against the code before you see it, so hallucinated findings die quietly. Also used internally
by `/tandem` as the pre-PR gate.

## Installation

Requires Claude Code and the [Codex CLI](https://github.com/openai/codex) (`codex login`
completed; without it, tandem degrades to a clearly-labeled single-model mode).

```bash
git clone git@github.com:mohammedagha27/tandem-skills.git
cd tandem-skills && ./install.sh        # symlinks both skills into ~/.claude/skills
```

Install both skills together — `/tandem` invokes `/tandem-review`, and `tandem-review` reads
the shared Codex protocol from the `tandem` skill directory.

## Configuration

None required. To change defaults per repo, create `.tandem/config.md`:

```
max_rounds: 3        # sparring round cap (default 5)
codex_review: on     # pre-PR feature review (on|off)
pr: ask              # ask|auto|off
ci: on               # watch CI after the PR opens
docs: on             # generate the dossier
autonomy: guided     # guided (pause at gates) | auto (only mandatory gates)
```

One-off overrides ride the invocation: `/tandem PROJ-123 rounds=3 review=off`.

## What a run leaves behind

- `.tandem/<slug>/` — working state (gitignore it). `state.md` holds requirements, decisions,
  disagreements, and deviations; it's what makes `/tandem resume` work.
- `docs/features/YYYY-MM-DD-<slug>.md` — the dossier: problem, requirements (assumptions
  called out), decisions with rejected alternatives, where the two models disagreed and how it
  resolved, verification evidence, known limitations. Project memory, not a transcript.
- The branch, PR, and a review log of the sparring rounds.

## Design notes

The architecture, the reasoning behind it, and everything studied to build it are in
[docs/DESIGN.md](docs/DESIGN.md). Validation scenarios and findings are in
[docs/VALIDATION.md](docs/VALIDATION.md). Short version: one orchestrator skill with per-phase
reference playbooks (loaded only when the phase starts), one standalone review skill,
structured state instead of transcript accumulation, severity-tagged verdicts instead of
binary approve/revise, and every Codex loop bounded with an honest-deadlock path.

## Attribution

The interview discipline in the understand phase, and the ancestry of this whole idea, come
from **Matt Pocock's** `grill-me` and `grill-with-docs` skills
(https://github.com/mattpocock/skills, MIT) — see [THIRD-PARTY-NOTICES.md](THIRD-PARTY-NOTICES.md).
The Codex CLI mechanics build on the `grill-me-codex` / `grill-with-docs-codex` derivatives
previously in this account, re-verified against codex-cli 0.146.0. This is a new project, not
a fork of either.

## Limitations

- The sparring loop is only as good as the reviewing model's repo access; Codex reads the repo
  itself, but it can't see your Claude session (MCP data, pasted context) unless it lands in
  `plan.md`/`state.md`.
- Codex CLI flags change between versions. The protocol was verified on 0.146.0; the preflight
  in `codex-protocol.md` says what to re-check on upgrades.
- `/tandem` is deliberately heavyweight. For a one-line fix, just make the fix.

## License

MIT — see [LICENSE](LICENSE).
