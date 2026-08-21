# state.md format + resume protocol

`.tandem/<slug>/state.md` is current-truth only — no history, no transcripts. If a section
would grow by appending, you're doing it wrong: supersede, don't accumulate. History lives in
`spar-log.md`, git, and ultimately the dossier.

## Template

```markdown
# Tandem: <slug>
phase: intake | understand | spar | plan-gate | build | ship | dossier | done
mode: full | plan | spar
branch: <feature branch, once created>
config: max_rounds=5 codex_review=on pr=ask ci=on docs=on autonomy=guided
spar: codex (thread <id>) | solo | skipped
updated: <ISO date>

## Task
<2-4 sentences: what and why, in the project's own terms>

## Sources
- <ticket/doc/link> — fetched | unfetched (<reason>) | pasted by user

## Requirements
- R1 (confirmed): <requirement> — accept: <how we'll know it's met>
- R2 (assumed): <requirement> — basis: <why this reading>; risk if wrong: <one line>
- R3 (open): <question> — blocking: yes|no

## Decisions
- D1: <choice>. Why: <one line>. Rejected: <alternative + one-line reason>.

## Disagreements
- G1: <topic>. Codex: <position>. Claude: <position>. Resolution: <accepted|rejected|user chose X> — <reason>.

## Spar rounds
- 1 (intent, BLOCKING): 2 accepted, 1 rejected — <one-line gist>
- 2 (architecture, skipped): settled during understand
…

## Build
- Baseline failures: <test ids that failed BEFORE any change, or "none">
- Done: <plan step ids completed>
- Deviations: V1: <what changed vs plan + why>  (also annotate plan.md)

## Verification
- <command> → <pass/fail + counts> (<date>)

## Ship
- Review: <tandem-review verdict + findings triaged: N fixed, M rejected>
- PR: <url or "not yet" or "off">
- CI: <green | failures: ours(...) / pre-existing(...)>

## Next
<the single next action — what a fresh session should do first>
```

R-ids, D-ids, G-ids, V-ids are stable once assigned; plan tasks and the dossier reference them.
That's the whole traceability mechanism — cheap on purpose.

## Resume protocol

On `/tandem resume`:

1. Read `state.md`. Do NOT re-read `spar-log.md` or old diffs.
2. Verify the recorded `phase` against reality before trusting it: branch exists? plan.md
   frozen? commits present? tests in the recorded state? Fix `state.md` to match reality if
   they disagree (reality wins), and note the correction.
3. Announce a 3-line recap to the user (task, phase, next action), then continue from `## Next`
   with the matching phase playbook.
4. A recorded Codex `thread` may be resumable; if resume fails, start a fresh session and give
   it a 3-bullet catch-up (current plan + settled points) rather than replaying the log.
