# Tandem

Claude Code skills that turn Claude and OpenAI Codex into complementary engineering partners
rather than two independent coding agents. Claude does the work; Codex attacks it at the two
points where a second model earns its keep: before any code exists (plan sparring) and before
the PR opens (whole-feature review). Codex is read-only at all times.

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

```
/tandem-review                          # current branch vs its detected base
/tandem-review against origin/develop   # name the base explicitly when it's ambiguous
```

## Prerequisites

- **Claude Code** (required).
- **[Codex CLI](https://github.com/openai/codex)** with `codex login` completed (recommended).
  Without it — or if Codex fails mid-run (quota, auth, network) — tandem applies your
  `codex_failure` policy: ask (default), stop resumably, or continue with clearly-labeled
  Claude fallback critics. It never fails silently and never passes off same-model review as
  cross-model.
- **git** (required — Codex refuses to run outside a git repo, and the workflow is built
  around branches).
- **`gh` CLI or a GitHub remote** (optional). Only the PR and CI-watch steps use it; without
  it, runs end at a pushed branch with the manual commands printed. Any issue tracker works
  for intake — tickets are fetched through whatever the session has (MCP tools, `gh`, or a
  plain URL fetch) and an unfetchable source falls back to asking you for a paste.

## Installation

Via the [skills.sh](https://skills.sh/mohammedagha27/tandem-skills/tandem) CLI (works for
Claude Code and other agents):

```bash
npx skills add mohammedagha27/tandem-skills
```

Or from a clone (symlinks track the repo, so `git pull` updates the skills):

```bash
git clone https://github.com/mohammedagha27/tandem-skills.git
cd tandem-skills && ./install.sh        # symlinks both skills into ~/.claude/skills
```

Install both skills together — `/tandem` invokes `/tandem-review`, and `tandem-review` reads
the shared Codex protocol from the `tandem` skill directory. Restart Claude Code (or open a
new session) to pick them up. The installer targets `~/.claude/skills` by default; set
`CLAUDE_SKILLS_DIR` to override. It uses symlinks (macOS/Linux; on Windows, use WSL or copy
the two `skills/*` directories instead).

To uninstall: remove the two symlinks (`rm ~/.claude/skills/tandem ~/.claude/skills/tandem-review`).

Your persistent defaults (`config.md` beside the tandem skill — see Configuration) are never
overwritten or removed by install or update; with the symlink install they live in your clone
and survive re-linking.

## Configuration

None required — everything has a sensible default. Persistent defaults live in a `config.md`
beside the installed tandem skill (e.g. `~/.claude/skills/tandem/config.md`; the file always
belongs to the installation that's actually loaded — global, project-level, or a custom
`CLAUDE_SKILLS_DIR` all work the same way). Manage it from inside Claude Code:

```
/tandem config                       # interactive: view and change defaults
/tandem config show                  # read-only view of built-in vs configured values
/tandem config execution=subagents   # set specific keys directly
/tandem config max_rounds=3 pr=auto
/tandem config reset                 # back to built-ins (asks first)
```

The ten keys: `codex` (on|off), `max_rounds`, `codex_review` (on|off), `execution`
(auto|inline|subagents), `pr` (ask|auto|off), `ci` (on|off), `docs` (on|off), `autonomy`
(guided|auto), `codex_failure` (ask|stop|claude — what happens if Codex becomes unavailable
mid-run: ask you, stop resumably, or continue with clearly-labeled Claude fallback critics),
`claude_fallback_model` (inherit|model id — the model those fallback critics use) — full
semantics in the skill's `references/config.md`. One-off overrides ride
the invocation and never touch your defaults: `/tandem PROJ-123 rounds=3 review=off`.

## What a run looks like

`/tandem Add rate limiting to the public API`, condensed:

1. **Intake** — no ticket to fetch; the prose is the source. Tandem finds the API entry
   points, middleware conventions, and the test layout, and writes requirement stubs to
   `.tandem/rate-limiting/state.md`.
2. **Understand** — it asks you only what the repo can't answer, one question at a time with
   a recommendation attached: "Per-user or per-IP limits? The auth middleware suggests
   per-user — recommend that." Scope-ambiguous questions are never guessed at.
3. **Spar** — it drafts `plan.md`, then Codex attacks it round by round (assumptions →
   architecture → edge cases → simplification → kill shot). Claude verifies each finding,
   folds in what's right, rejects what's wrong with a logged reason. Simple plans converge in
   2–3 rounds; the cap (default 5) is a ceiling, not a target.
4. **Plan gate** — you see the hardened plan, the surviving disagreements, and the live
   assumptions in one message, and sign off.
5. **Build** — feature branch, baseline test snapshot, small verified increments; deviations
   from the plan are logged, never silent. Multi-task plans dispatch a fresh subagent per
   task, each fed a standalone brief, so the main session stays lean; small coupled changes
   run inline.
6. **Ship** — fresh verification, then `/tandem-review` runs Codex over the whole branch,
   findings are verified and triaged, and the dossier (problem, decisions, disagreements,
   evidence) is committed before the PR opens. PR and CI-watch follow your config.

Interrupt it anywhere; `/tandem resume` picks up from the state file, verifying the recorded
phase against reality before trusting it. To abandon a run instead, delete its
`.tandem/<slug>/` directory — everything durable lives in git and the dossier.

## What a run leaves behind

- `.tandem/<slug>/` — working state, kept out of git via `.git/info/exclude` (never a
  preferences file). `state.md` holds requirements, decisions, disagreements, and deviations;
  it's what makes `/tandem resume` work.
- `docs/features/YYYY-MM-DD-<slug>.md` — the dossier: problem, requirements (assumptions
  called out), decisions with rejected alternatives, where the two models disagreed and how it
  resolved, verification evidence, known limitations. Project memory, not a transcript.
- The branch, PR, and a review log of the sparring rounds.

## Privacy & security

- **Repo content goes to OpenAI.** Codex reads your repository and receives the plan/state
  files in its prompts; that content is processed by OpenAI under your Codex account's terms,
  and the calls consume your Codex/ChatGPT plan's quota. To keep repo content away from
  OpenAI entirely, set `codex: off` — the whole workflow then runs single-model (sparring and
  review by Claude, labeled as such). This is an OpenAI opt-out, not a fully-local mode:
  Claude Code itself still processes your repo through Anthropic, as in any other session.
  Note that `codex_review: off` alone is *not* a privacy switch: it only skips the pre-PR
  review gate, and plan sparring still calls Codex.
- **Codex is read-only, enforced per call.** Fresh sessions run `-s read-only`; resumed
  sessions force `-c sandbox_mode="read-only"` (resume would otherwise inherit your
  `~/.codex/config.toml`, which may allow writes).
- **All writes, commits, pushes, and PRs come from Claude**, under Claude Code's normal
  permission prompts. PRs default to ask-first.
- **Third-party text is treated as data, not instructions.** Fetched tickets/docs and Codex
  replies can contain prompt-injection attempts; the skills flag instruction-shaped content
  instead of following it, and no review suggestion is ever executed without verification.

## Troubleshooting

- **Skills don't appear after install** — restart Claude Code; check the symlinks point where
  you cloned (`ls -l ~/.claude/skills/tandem*`).
- **Codex calls fail immediately** — run `codex login`; check `codex --version` (protocol
  verified on 0.146.0; the preflight in `skills/tandem/references/codex-protocol.md` says what
  to re-check on other versions).
- **Codex hangs at ~0% CPU** — something invoked it without stdin discipline; the protocol
  file documents the fix (prompt via `- <file`), which the skills already follow.
- **Mid-run interruption** — nothing is lost; state is on disk. `/tandem resume` continues.

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
The Codex CLI mechanics were worked out by this project's author in earlier unpublished
experiments and re-verified against codex-cli 0.146.0 for this project. This is a new
project, not a fork.

## Limitations

- The sparring loop is only as good as the reviewing model's repo access; Codex reads the repo
  itself, but it can't see your Claude session (MCP data, pasted context) unless it lands in
  `plan.md`/`state.md`.
- Codex CLI flags change between versions. The protocol was verified on 0.146.0; the preflight
  in `codex-protocol.md` says what to re-check on upgrades.
- `/tandem` is deliberately heavyweight. For a one-line fix, just make the fix.

## License

MIT — see [LICENSE](LICENSE).
