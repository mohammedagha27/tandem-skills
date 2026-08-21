# Configuration — the single contract

Schema, defaults, aliases, validation, path resolution, precedence, and the `/tandem config`
mode are all defined HERE and only here. Lifecycle kickoff, resume, and `tandem-review` refer
to this file instead of restating any of it.

## Schema and defaults

| Key | Values | Default | Meaning |
|---|---|---|---|
| `codex` | `on\|off` | `on` | `off` = never invoke the Codex CLI anywhere in a run: sparring, mid-build spot-checks, and the pre-PR review all run single-model (solo mode *by choice*, recorded as `spar: solo (by config)` — no failure-ladder framing). For repos whose content must not go to OpenAI, or machines without Codex. |
| `max_rounds` | positive integer | `5` | Hard cap on sparring rounds. The loop always terminates here. |
| `codex_review` | `on\|off` | `on` | Pre-PR feature-level review via the `tandem-review` skill (single-model self-review when `codex=off`). |
| `execution` | `auto\|inline\|subagents` | `auto` | Build execution model. `auto` = classify per the build playbook; `inline`/`subagents` force that model. |
| `pr` | `ask\|auto\|off` | `ask` | `ask` = confirm before opening a PR; `auto` = open it; `off` = stop at a pushed branch. |
| `ci` | `on\|off` | `on` | Monitor CI checks after the PR opens (no-op when no PR exists). |
| `docs` | `on\|off` | `on` | Generate and commit the dossier (full mode only). |
| `autonomy` | `guided\|auto` | `guided` | `guided` = pause at gates (questions, plan sign-off). `auto` = proceed through normal gates; destructive, security-sensitive, or scope-ambiguous decisions — and sparring deadlocks — always ask, in every mode. |

Aliases, accepted in the config file and as invocation args: `rounds` ≡ `max_rounds`,
`review` ≡ `codex_review`. Store the canonical name when writing the file.

## Where the persistent config lives — path resolution

There is exactly ONE persistent scope: the **active Tandem installation**.

```
<TANDEM_SKILL_DIR>/config.md
```

`<TANDEM_SKILL_DIR>` is the directory containing the `SKILL.md` that was actually loaded this
session. Never hardcode `~/.claude` — the skill may be installed globally
(`~/.claude/skills/tandem/`), at project level (`<project>/.claude/skills/tandem/`), under a
custom `CLAUDE_SKILLS_DIR`, or through a symlink; the rule is the same in every case: the
config sits beside the loaded `SKILL.md`.

- **Symlinked install** (this repo's `install.sh`): the skill dir is a symlink into the
  clone, so reading/writing `<TANDEM_SKILL_DIR>/config.md` lands on one physical file inside
  the clone. Intended: one file, no accidental second copy, survives re-linking. (This repo
  gitignores `skills/*/config.md` so a personal config never enters version control of the
  skill repo itself.)
- **Two installations** (global AND project): only the loaded one and its config apply.
  Never merge installation configs or invent precedence between them.
- **Missing `config.md`** = built-in defaults. Only a user-requested save via
  `/tandem config` creates the file — an ordinary run never does.
- **`tandem-review`** resolves the same file relative to its sibling: the `tandem` skill
  directory installed next to it. It never has a config file of its own.

Legacy note (pre-release location): `.tandem/config.md` in a repo is **not read**. Intake's
repo-discovery step checks for it; if found, say so once per run and offer to copy its valid
values into the installation config — never read it silently.

## File format

`key: value`, one per line. Lines starting with `#` and blank lines are ignored. Nothing
else — no sections, no quoting, no nesting. When editing, preserve everything you aren't
changing: comments, blank lines, and other lines valid or not (see Validation).

## Validation

- Unknown key: warn once (`unknown key 'X' — ignored`), continue.
- Invalid value (`max_rounds: 0` or non-numeric, an unrecognized enum — same rule for config
  file lines and invocation args): at run kickoff, warn once and **drop that assignment** —
  resolution continues with the next-lower precedence layer (an invalid invocation arg falls
  back to the installation value, an invalid installation value to the built-in). In config
  mode, refuse to write it. Never guess a meaning.
- A pre-existing invalid or unknown line found while editing other keys is preserved and
  warned about, never silently dropped — the user wrote it; they remove it.

## Runtime precedence

```
built-in defaults → active installation config.md → invocation args (key=value tokens)
```

Resolve once at kickoff, record the RESOLVED values on `state.md`'s `config:` line, and echo
them once. Invocation args win for that run only — they never mutate the installation config.
On `/tandem resume`, the config recorded in `state.md` wins unless the resume invocation
explicitly passes new values (deterministic resume: editing installation defaults never
retroactively changes an in-flight run).

## `/tandem config` — the configuration mode

`config` as the bare first token enters this mode. It **never** starts intake, creates run
state, branches, or invokes Codex — it reads and writes one file, then exits. Route
natural-language asks here too ("configure tandem defaults", "change tandem's default
rounds") when no feature work is being requested.

First, always: resolve `<TANDEM_SKILL_DIR>/config.md`. Two conditions guard **write
operations only** (`show` and a declined interactive session never trigger them):

- **Tracked file:** before writing, check whether the file is git-tracked
  (`git ls-files --error-unmatch <path>` in its directory) — project-level installs may share
  it with the team. If tracked, say clearly that the change affects the whole project/team
  and get an explicit confirmation before writing. Never edit `.gitignore` on the user's
  behalf.
- **Read-only installation:** when a write fails (or a preflight shows the directory isn't
  writable), report the exact path and the error; do NOT fall back to writing anywhere else.

Operations:

- `/tandem config` (interactive): state the file path (or "none — built-in defaults in
  effect") in one line — don't dump the full table first; that's `show`'s job. Then drive
  the changes with the harness's **interactive question tool** (`AskUserQuestion` in Claude
  Code — the arrow-key picker), never open-ended prose questions:
  1. One multi-select question — "Which settings do you want to change?" — with the eight
     keys grouped into at most 4 options, each labeled with its current values, e.g.
     `Codex — codex=on, max_rounds=5, codex_review=on`, `Build — execution=auto`,
     `Ship — pr=ask, ci=on, docs=on`, `Gates — autonomy=guided`.
  2. For each selected group, one question per key: the allowed values as options, the
     current value listed first and marked `(current)`; numeric keys offer common values
     (3, 5, 7) with free entry via the picker's Other.
  Nothing selected, or the user declines? Exit without writing. Otherwise validate, write
  only the selected changes (preserving everything else), and show the resulting file and
  its path. No interactive picker in this harness? Fall back to ONE compact text question
  listing the `key=value` choices.
- `/tandem config show` — read-only. A table of key | built-in | configured (`—` if unset) |
  resolved, plus the active file path. Never writes, never creates the file.
- `/tandem config key=value [key=value …]` — validate each assignment; invalid or unknown
  ones get the warning and are NOT written (valid ones in the same call still are); update
  only the named keys, preserve everything else, then show the result and path.
- `/tandem config reset` — no file? Report "built-in defaults already in effect" and write
  nothing. Otherwise confirm first ("restore built-in defaults — remove the overrides at
  <path>?"), then rewrite the file to the canonical empty form below (or delete just that
  file if the user prefers). Touch nothing else.

Canonical empty form (what `reset` writes):

```
# tandem defaults — key: value per line; see the tandem skill's references/config.md
```
