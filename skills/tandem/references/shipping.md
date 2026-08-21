# Ship — verify, review, PR, CI

Iron law throughout: **no completion claims without fresh verification evidence in the current
message.** "Should pass" and yesterday's run don't count.

## 1. Full verification

Run the full relevant suite + linters + build (whatever the repo's CI would run). Compare
failures against `state.md § Build → Baseline failures`:

- New failures → fix before anything else.
- Pre-existing failures → list them explicitly as pre-existing (with the baseline as evidence);
  they don't block, but they get reported to the user and noted in the dossier.

Record commands + results in `state.md § Verification`.

## 2. Feature review gate (`codex_review=on`)

Invoke the **tandem-review** skill on the feature branch — it reviews the whole feature
(merge-base → HEAD + working tree), not the last diff, and knows to read `plan.md`/`state.md`
for requirements coverage. Pass it the slug so it finds the tandem context.

Triage its triaged output (tandem-review already verifies findings against the code):

- Fix accepted findings; log the round in `state.md § Ship`.
- Re-reviews resume the SAME Codex session over the fix delta ("here's what changed since
  your review: …") — not a fresh whole-branch pass.
- Cap: **2 fix-and-re-review cycles**, counted per feature branch (a fresh Codex session does
  not reset it). Still MATERIAL+ after that → present the remainder to the user with positions
  rather than looping; each further cycle happens only on their explicit per-cycle ask. Rerun
  step 1 verification after any fix.

If Codex is unavailable (or `codex=off`), degrade per its protocol: a Claude self-review pass
against the examine-list in tandem-review's prompt (correctness, requirements coverage, architecture fit,
regressions, edge cases, security, performance, maintainability, test quality, complexity,
plan deviations), recorded as single-model.

## 3. Dossier (per `docs` config)

Render and commit the dossier now, on the feature branch, per `dossier.md` — before the PR
opens, so it rides the PR and never invalidates a watched CI run. With `pr=off`, push the
branch after this commit — the pushed branch is the end state.

## 4. PR (per `pr` config)

`off` → push the branch, report, skip to step 5. `ask` (default) → present the summary and ask
before opening. `auto` → open it. Opening a PR is outward-facing: when in doubt, ask.

- Push with `-u`. Look for a PR template (`.github/PULL_REQUEST_TEMPLATE*`) and use it.
- PR body: what + why from `state.md § Task/Decisions` (not a commit list), test plan from
  `§ Verification`, plus notable disagreements/deviations a reviewer should know. Link the
  ticket so the tracker auto-links.
- PR creation fails (permissions, no remote, protected branch, non-GitHub host)? Report the
  exact error, give the platform-appropriate manual command (`gh pr create …` on GitHub; the
  host's merge-request URL or CLI elsewhere), leave the branch pushed. Not a workflow failure.

## 5. CI (per `ci` config — no-op when no PR exists)

`gh pr checks <url> --watch` (or poll if watch is unavailable). On failures, read the actual
logs, then classify:

- **Ours** (touched code, new tests, baseline-green now red) → fix, push, re-watch.
  Bounded: after 3 fix-pushes without green, stop and hand the analysis to the user.
- **Pre-existing/unrelated** (matches baseline failures, flaky-marked, infrastructure) →
  report separately with evidence; never "fix" unrelated tests to force green without the
  user's say-so.

## 6. Done

Update `state.md`: phase `done`, `§ Ship` complete, `§ Next` cleared, one closing summary
line. Report to the user: what shipped, verification evidence, review outcome, dossier path,
PR/CI state, pre-existing issues found along the way.
