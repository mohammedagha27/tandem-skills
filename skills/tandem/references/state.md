# state.md format + resume protocol

`.tandem/<slug>/state.md` is current-truth only — supersede rather than accumulate. The
header block (`phase:` through `updated:`) is parsed line-by-line: each field is exactly ONE
physical line, however long — never wrap the `config:` line mid-value. Two
exceptions are append-shaped by design because they are bounded, dossier-feeding logs:
`## Spar rounds` (one line per round — bounded by `max_rounds` plus at most one `SC<n>`
spot-check line per reopened build decision) and `## Verification` (one line per run).
Everything else gets replaced when it changes. Full history lives in `spar-log.md`,
git, and ultimately the dossier.

## Template

```markdown
# Tandem: <slug>
phase: intake | understand | spar | plan-gate | planned | build | ship | done
mode: full | plan | spar
branch: <feature branch, once created>
base: <branch it was cut from, e.g. origin/main>
config: codex=on max_rounds=5 codex_review=on execution=auto pr=ask ci=on docs=on autonomy=guided codex_failure=ask claude_fallback_model=inherit
spar: pending | codex (thread <id>) | solo (by config) | claude-fallback (model <m>, since round <n>[, was codex thread <id>]) | skipped (user instruction, <date>)
codex-failure: <omit unless Codex became unavailable: at <stage/round> — reason → policy (ask|stop|claude) → outcome (user chose stop|claude|retry / stopped / fallback, model <m>)[; explicit codex retry at <stage>: succeeded|failed]>
updated: <ISO datetime>

## Task
<2-4 sentences: what and why, in the project's own terms.
"unknown — sole source unfetched" is legal while awaiting a paste.>

## Sources
- <ticket/doc/link> — fetched | unfetched (<attempted command + error>) | pasted by user

## Requirements
- R1 (confirmed): <requirement> — accept: <how we'll know it's met>
- R2 (assumed): <requirement> — basis: <why this reading>; scope: no; risk if wrong: <one line>
- R3 (open): <question> — scope: yes|no

## Decisions
- D1: <choice>. Why: <one line>. Rejected: <alternative + one-line reason>.

## Disagreements
- G1 (BLOCKING|MATERIAL|MINOR): <topic>. Codex: <position>. Claude: <position>. Resolution: <accepted|rejected|user chose X|unresolved> — <reason>.

## Spar rounds
- 1 (intent, BLOCKING): 2 accepted, 1 rejected — <one-line gist>
- 2 (architecture, skipped): settled during understand
- 3 (edge cases, MATERIAL) [fallback]: … — rounds run by a Claude critic carry [solo] or [fallback]
…

## Build
- Baseline failures: <test ids that failed BEFORE any change, or "none">
- Execution: inline | subagents — <one-line reason, or "set in config/invocation">
- Done: <TASK ids completed>
- Last commit: <sha> (<TASK id>)
- In progress: <TASK id> — uncommitted changes: yes|no
- Task reviews: TASK-<n>: <N fixed / M rejected (reason) / waived by user> (subagent builds; only reviewed tasks)
- Deviations: V1: <what changed vs plan + why>  (also annotate plan.md)

## Verification
- <command> → <pass/fail + counts> (<datetime>)

## Ship
- Review: <tandem-review verdict + findings triaged: N fixed, M rejected>[ (Claude fallback critic, model <m>) | (solo review — codex off)]
- Dossier: <path, once committed>
- PR: <url or "not yet" or "off">
- CI: <green | failures: ours(...) / pre-existing(...)>

## Next
<the single next action — what a fresh session should do first>
```

R-ids, D-ids, G-ids, V-ids are stable once assigned; plan tasks and the dossier reference them.
That's the whole traceability mechanism — cheap on purpose.

The `scope:` tag on requirements uses one test everywhere (the Understand gate's
"shape-changing", the plan gate's "scope-changing", and escalation all mean this): **two
reasonable readings would deliver different things** — different deliverable, different
surfaces touched, different acceptance line. `scope: yes` items are the user's to resolve in
every autonomy mode and are never converted to assumptions.

## Resume protocol

On `/tandem resume`:

1. Read `state.md` AND `plan.md`. Do NOT re-read `spar-log.md` or old diffs.
2. Verify the recorded `phase` against reality with cheap checks before trusting it: does
   `branch` exist? does `git log` reach `Last commit`? is the working tree dirty (compare with
   `In progress`)? Uncommitted changes found there are likely half-finished work — inspect the
   diff before touching them; never stash or discard them blind. Re-run tests only if
   `## Verification` is stale relative to `Last commit`. Reality wins: fix `state.md` to match
   it and note the correction.
3. Config: the `config:` line in state holds the RESOLVED values from kickoff and wins,
   unless the resume invocation passes new args (contract: `references/config.md`) —
   installation-config edits made since kickoff do not retroactively change this run.
4. Announce a 3-line recap to the user (task, phase, next action), then continue from `## Next`
   with the matching phase playbook.
5. A recorded Codex `thread` may be resumable; if the resume fails, follow the protocol's
   failure ladder and then the `codex_failure` policy.
6. A run that entered Claude fallback mode (`spar: claude-fallback…`) STAYS in fallback mode
   after resume — never re-ask about Codex stage by stage. Only an explicit resume-time
   override (the user asks to retry Codex or changes the policy) reopens it; log the retry's
   outcome on the `codex-failure:` line. A run STOPPED by the policy resumes from `§ Next`:
   when `§ Next` names a Codex condition ("continue once quota renews"), retrying Codex IS
   the recorded next step — attempt it and log the outcome, no extra ask needed. In every
   case, completed rounds and reviews are never re-run.
