# Test Sweep

A sweep audits the whole test surface of a repository or subsystem. The junk patterns, retention bar, candidate evidence, and validation in [SKILL.md](SKILL.md) apply to every area. This file adds the order of work. Finish each step before you start the next one.

## Keep the State Outside the Repository

Write the baseline, area map, ledgers, and plans to files outside tracked paths, such as a session scratch directory or a gitignored path. A sweep outlives one context window, and later steps read these files as input.

## 1. Baseline

Pin a commit SHA on the default branch. Record the pass or fail state of every in-scope test file at that SHA. Keep baseline failures in a separate list. They can be real product bugs, not stale tests.

Done when every in-scope test file has a recorded baseline result.

## 2. Area Map

Split the surface into areas along production owner boundaries, not file prefixes or directory names. Derive the areas from the code, the scoped `AGENTS.md` files, and CI routing. Include the subsystem's cases at shared boundaries and its integration or end-to-end harness tests.

Done when every in-scope test file belongs to exactly one area.

## 3. Ledger per Area

Give each area to its own read-only subagent. The subagent reads every assigned test in full, including parameter tables. It also reads the production owners, entry points, callers, history, and CI routing.

The subagent writes one ledger line per test declaration, with one mark and one evidence line. Treat a table-driven test as one declaration unless its rows need different marks; then mark each row.

- `R` (retain): name the contract and the bug that the test catches. A test that only moves to a better location stays `R`, with the move noted.
- `F` (fix): the contract is real, but the assertion is weak. An example is a negative check that passes when only one of several items is missing.
- `C` (consolidate): name the owner that absorbs the assertion, such as a sibling table case, a stronger boundary suite, or a shared owner in another package.
- `D` (delete): name the proof that remains, or explain why no contract exists.

Done when every declaration in the area has a mark and an evidence line.

## 4. Layer Plan per Area

Treat the ledger as input, not as the edit list. A second read-only pass starts from the ledger and looks for redundant layers: whole suites that replay a contract that a stronger suite already proves. Name one keeper suite for each contract. Prefer the real transport or storage boundary with a fake dependency over a mocked collaborator. Correct any ledger errors that this pass finds.

Done when each area plan names:

- the retired files;
- the keeper for each contract;
- the assertions to carry into the keepers;
- the test-only production seams that the plan unlocks.

## 5. Cutover

Edit area by area. Give shared test harnesses and support files to one owner, and serialize changes to them. With each area, remove the test-only production seams that it unlocks: injection parameters, getters, reset exports, and indirection layers. Update CI routing and test inventories for moved suites.

Put durable test-ownership rules in the applicable `AGENTS.md`. Base them on mistakes that this sweep actually found.

Done when every area plan is applied and the keepers for each area pass.

## 6. Preservation Review

Before you claim completion, have independent reviewers compare the deleted coverage with the keepers. Use one reviewer per group of related areas. The reviewers look for:

- contracts that lost their only proof;
- new or moved assertions that cannot fail, such as a rejection case that the production code never reaches.

For each restored contract, make one deliberate break in the production owner and confirm that the keeper fails. Then restore the source exactly, and confirm with `git diff` that no change remains.

Done when every reported gap is restored or rejected with source evidence, and every restored contract has a caught break.

## 7. Product Defects

A baseline failure that survives into a keeper is a bug report. Fix it at its owner in a separate commit. Prove the fix with a control run: revert the fix, confirm that the keeper fails, then reapply the fix and confirm that it passes. Record unrelated product problems as follow-ups. Do not fix them in the sweep.

Done when each repaired defect has a failing control run and a passing run on the same harness.

## 8. Reconcile and Hand Off

When the default branch moves during the sweep, integrate it before handoff. If the default branch modified a file that the sweep deleted, keep the deletion and move the new contract into the keeper. Confirm that every new regression test from the default branch still has a home. Rerun the whole in-scope suite on the final head.

Hand off with the report from [SKILL.md](SKILL.md), plus:

- the areas, retired layers, and keepers;
- the preservation gaps found and the breaks that proved each restored contract;
- the product defects, with control and fixed runs.
