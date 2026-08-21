# Ship — verify, review, PR, CI

Iron law throughout: **no completion claims without fresh verification evidence in the current
message.** "Should pass" and yesterday's run don't count.

## 1. Full verification

Run the full relevant suite + linters + build (whatever the repo's CI would run). Compare
failures against `state.md § Build → Baseline failures`:

- New failures → fix before anything else.
- Pre-existing failures → list them explicitly as pre-existing (with the baseline as evidence);
  they don't block, but they get reported to the user and noted in the dossier.

Then the **requirements checklist**: walk EVERY R-id in `state.md` against its `accept:`
line and name the evidence (test id, command output, file:line). A green suite is not this
proof — a suite with a missing feature also passes. Gaps block the ship and reopen Build (or
the plan, per the deviation protocol).

Record commands + results + the checklist outcome in `state.md § Verification`.

## 2. Feature review gate (`codex_review=on`)

Invoke the **tandem-review** skill on the feature branch — it reviews the whole feature
(merge-base → HEAD + working tree), not the last diff, and knows to read `plan.md`/`state.md`
for requirements coverage. Pass it the slug so it finds the tandem context, and state the
resolved config explicitly — `codex` and the recorded `base:` in particular travel with the
call; the reviewer honors the run's state over repo defaults.

Triage its triaged output (tandem-review already verifies findings against the code):

- Fix accepted findings in severity order — blocking first, then simple, then complex —
  verifying each fix in isolation (focused test) before moving to the next; log the round in
  `state.md § Ship`.
- Re-reviews resume the SAME Codex session over the fix delta ("here's what changed since
  your review: …") — not a fresh whole-branch pass. The delta includes the disposition of
  every prior finding — fixed (where), rejected (with evidence), or consciously deferred —
  so settled points aren't re-litigated.
- Cap: **2 fix-and-re-review cycles**, counted per feature branch (a fresh Codex session does
  not reset it). Still MATERIAL+ after that → present the remainder to the user with positions
  rather than looping; each further cycle happens only on their explicit per-cycle ask. Rerun
  step 1 verification after any fix.

If Codex is unavailable here, apply the `codex_failure` policy
(`codex-protocol.md § Codex unavailable`) — a run already in Claude fallback mode just
continues in it, without re-asking. With `codex=off`, run the single-model pass by choice
(no failure framing). In both single-model cases the review is a **fresh Claude critic
subagent** (model: `claude_fallback_model`, disclosed; labeled "Claude fallback critic" in
the failure case, "solo review" under `codex=off`) against the examine-list in
tandem-review's prompt (correctness, requirements coverage, architecture fit, regressions,
edge cases, security, performance, maintainability, non-author readability, test quality,
complexity, plan deviations) — under the **same output contract as the Codex path**: severity-tagged
findings, a final verdict line, triage into the same buckets, and the orchestrator verifies
every finding before acting. Never use an implementation subagent to review its own work; if
subagents are unavailable, an orchestrator self-review is the last resort, marked as such.
A paragraph of "looks fine" does not satisfy this step. Record which reviews ran single-model
in `state.md § Ship`.

## 3. Dossier (per `docs` config)

Render and commit the dossier now, on the feature branch, per `dossier.md` — before the PR
opens, so it rides the PR and never invalidates a watched CI run. With `pr=off`, push the
branch after this commit — the pushed branch is the end state.

## 4. PR (per `pr` config)

`off` → push the branch, report, skip to step 5. `ask` (default) → present the summary and ask
before opening. `auto` → open it. Opening a PR is outward-facing: when in doubt, ask.

- Push with `-u`. Look for a PR/MR template (`.github/PULL_REQUEST_TEMPLATE*`,
  `.gitlab/merge_request_templates/`) and use it.
- PR body: what + why from `state.md § Task/Decisions` (not a commit list), test plan from
  `§ Verification`, plus notable disagreements/deviations a reviewer should know. If any
  material review or sparring ran on a same-model Claude critic (fallback or `codex=off`),
  disclose that plainly — never present it as a cross-model review. Link the ticket so the
  tracker auto-links.
- PR creation fails (permissions, no remote, protected branch, non-GitHub host)? Report the
  exact error, give the platform-appropriate manual command (`gh pr create …` on GitHub; the
  host's merge-request URL or CLI elsewhere), leave the branch pushed. Not a workflow failure.

## 5. CI (per `ci` config — no-op when no PR exists)

On GitHub: `gh pr checks <url> --watch` (or poll if watch is unavailable). On other hosts, use
the host's equivalent when one exists (e.g. `glab ci status` on GitLab); if there's no usable
CLI/API, say CI can't be watched from here and give the pipeline URL — don't silently no-op.
On failures, read the actual logs, then classify:

- **Ours** (touched code, new tests, baseline-green now red) → fix, push, re-watch.
  Bounded: after 3 fix-pushes without green, stop patching — three failed fixes is evidence
  a *decision* is wrong, not bad luck. Root-cause it per the build playbook's mid-build
  debugging rule and reopen the decision via the deviation protocol (with the user if it's
  theirs).
- **Pre-existing/unrelated** (matches baseline failures, flaky-marked, infrastructure) →
  report separately with evidence; never "fix" unrelated tests to force green without the
  user's say-so.

## 6. Done

Build worktree end-of-life: on the PR path, LEAVE it alive — review feedback iterates there;
name its path in the report. With no PR (`pr=off` or declined) and the work integrated or
consciously abandoned: exit it first (native tool, or cd to the main checkout root), then
`git worktree remove <path>` BEFORE any branch deletion — and never delete a branch a PR
references. Confirm before discarding anything unmerged.

Update `state.md`: phase `done`, `§ Ship` complete, `§ Next` cleared, one closing summary
line. Report to the user: what shipped, verification evidence, review outcome, dossier path,
PR/CI state, pre-existing issues found along the way.
