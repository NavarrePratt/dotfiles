// implement-workflow.js - generic multi-agent epic-implementation engine.
//
// This is the reusable engine behind the /implement-workflow skill. The skill
// owns the human-facing ritual: precondition checks, worktree creation, epic
// resolution into a linear bead order, assembling the args object below,
// launching this Workflow, and the post-run reconciliation + PR description.
// This engine only implements, commits, reviews, and fixes inside the worktree
// the skill hands it. It NEVER runs a git remote operation, never pushes, and
// never creates a PR - those stay with the user, past the end of this engine.
//
// The engine reads all per-run configuration from the `args` global (the object
// passed as Workflow({ name, args })). Agents spawned by this engine do NOT see
// `args`; every value an agent needs is interpolated into its prompt string
// here. The guard and config log at the top run before any agent is spawned, so
// a missing or malformed arg fails loudly and cheaply instead of deep in a run.

export const meta = {
  name: 'implement-workflow',
  description:
    'Implement one epic end-to-end from a resolved plan: burn down its beads in dependency order in a shared worktree, group them into self-verifiable commits (code, tests, and docs co-located), run a multi-lens code review (focused reviewers each self-validating with Codex), auto-apply confirmed findings folded into their commits, and return a structured report. Driven by the /implement-workflow skill, which owns the worktree ritual and PR description. This engine never pushes and never creates a PR.',
  phases: [
    { title: 'Implement', detail: 'one fork agent per bead, in dependency order, in the shared worktree' },
    { title: 'Commit', detail: 'group into self-verifiable commits - code + its tests + docs together, one coherent change each - matching the repo commit conventions, verifying each commit builds independently' },
    { title: 'Review', detail: 'focused-lens reviewers plus optional domain and decision-doc conformance lenses, each self-validating with Codex, in parallel' },
    { title: 'Fix', detail: 'auto-apply confirmed findings, fold into commits via fixup + autosquash, re-verify' },
  ],
}

// =====================================================================
// args contract - read from the `args` global (the /implement-workflow skill
// assembles and passes it). Agents never see `args`; the engine interpolates
// every field into the prompt strings below.
//
//   epicId            string    the epic being implemented this run
//   epicTitle         string?   human label for logs (optional)
//   beadsDb           string    absolute path to the MAIN checkout's
//                               .beads/beads.db (the worktree has none)
//   worktree          string    absolute worktree path; all work happens here
//   baseRef           string    diff/verify base: branch, ref, or SHA
//                               (the BASE in `git diff BASE..HEAD`)
//   beadOrder         string[]  leaf bead IDs in strict dependency
//                               (topological) order; implemented SEQUENTIALLY
//                               in the one shared worktree (no parallelism)
//   reviewLenses      string[]  e.g. ["correctness","simplicity","testing",
//                               "security","architecture"]
//   briefDir          string    reviewer brief directory; a lens with no brief
//                               falls back to general lens expertise
//   verify            object    repo commands { build?, test?, lint?, generate? };
//                               an empty or absent command skips that step
//   domainLens        string?   optional domain lens name; appended when set
//   designRecordsGlob string?   optional; ENABLES the report-only conformance
//                               lens ONLY when set (no-op when absent)
// =====================================================================
if (typeof args === 'undefined' || args === null) {
  throw new Error('implement-workflow: no args provided; launch this engine with Workflow({ name, args }) from the /implement-workflow skill')
}
for (const key of ['epicId', 'beadsDb', 'worktree', 'baseRef', 'beadOrder', 'reviewLenses', 'briefDir', 'verify']) {
  if (args[key] === undefined || args[key] === null) throw new Error(`implement-workflow: missing args.${key}`)
}
if (!Array.isArray(args.beadOrder) || args.beadOrder.length === 0) {
  throw new Error('implement-workflow: args.beadOrder must be a non-empty array')
}

const br = (a) => `br --db ${args.beadsDb} ${a}`

// Resolve the diff/verify base to a commit once; every phase reuses this.
const BASE_EXPR = `$(git rev-parse --verify "${args.baseRef}^{commit}")`
// build/test/lint that are actually configured; empties are skipped everywhere.
const fallbackVerify = [args.verify.build, args.verify.test, args.verify.lint].filter(Boolean)
const activeLenses = [...args.reviewLenses, ...(args.domainLens ? [args.domainLens] : []), ...(args.designRecordsGlob ? ['conformance'] : [])]

// Log the resolved config BEFORE spawning any agent, so the skill can eyeball
// this first line and confirm args arrived before the run goes deep.
log('implement-workflow config resolved:')
log(`  epic:     ${args.epicId}${args.epicTitle ? ` (${args.epicTitle})` : ''}`)
log(`  worktree: ${args.worktree}`)
log(`  base:     ${args.baseRef}`)
log(`  beads:    ${args.beadOrder.join(', ')}`)
log(`  lenses:   ${activeLenses.join(', ')}`)
log(`  verify:   build=${args.verify.build || '(skip)'} test=${args.verify.test || '(skip)'} lint=${args.verify.lint || '(skip)'} generate=${args.verify.generate || '(skip)'}`)

const CONVENTIONS = `
Constraints:
- Work ONLY inside the worktree at ${args.worktree}. cd there first; use absolute paths under it.
- Read existing code before editing. Match existing patterns. Keep changes minimal and scoped to this bead's Acceptance Criteria - do not expand scope.
- Co-locate tests and docs WITH the code they cover, in the SAME bead and commit: implement the change, its tests, and the nearest AGENTS.md / docstring updates together. NEVER defer tests or docs to a separate bead or commit. Each change must be independently verifiable - its tests compile and pass against only the code in this bead and the beads below it, never a forward reference to code a later bead introduces.
- Shared test infrastructure (a harness, fixtures, a fake) belongs in the EARLIEST bead whose own tests need it AND that can compile it. Later beads' tests reuse it.
- Comments and docs describe current state only. NEVER reference beads (bead IDs or bead labels) anywhere committed - code, comments, commit messages, AGENTS.md, docs: beads are local-only. At every "simple now, change later" point, leave a TODO that names the current behavior and the deferral, citing the tracker ticket if one exists (never a bead ID, never a milestone label). Keep docstrings concise and layer-appropriate.
- Do NOT run git or gs commands, do NOT commit, do NOT push. Leave all changes in the working tree for the commit phase.
- Do NOT touch TaskCreate/TaskUpdate.
`

const BEAD_RESULT_SCHEMA = {
  type: 'object',
  additionalProperties: false,
  required: ['bead', 'status', 'files', 'summary', 'verification'],
  properties: {
    bead: { type: 'string' },
    status: { type: 'string', enum: ['done', 'skipped'] },
    files: { type: 'string', description: 'comma-separated paths created/modified' },
    summary: { type: 'string', description: 'one paragraph: what was implemented and why' },
    discoveries: { type: 'string', description: 'TODOs/bugs/follow-ups, or "none"' },
    verification: { type: 'string', description: 'per-command pass/fail with brief notes' },
  },
}

// Adapted from /team-branch-review: each reviewer collects findings then
// self-validates them with Codex, tagging a verdict per finding.
const FINDINGS_SCHEMA = {
  type: 'object',
  additionalProperties: false,
  required: ['lens', 'outcome', 'findings'],
  properties: {
    lens: { type: 'string' },
    outcome: { type: 'string', description: 'one-line self-assessment after Codex validation' },
    findings: {
      type: 'array',
      items: {
        type: 'object',
        additionalProperties: false,
        required: ['title', 'file', 'severity', 'category', 'issue', 'suggestion', 'confidence', 'verdict'],
        properties: {
          title: { type: 'string' },
          file: { type: 'string', description: 'path:line' },
          severity: { type: 'string', enum: ['critical', 'high', 'medium', 'low'] },
          category: { type: 'string' },
          issue: { type: 'string' },
          suggestion: { type: 'string' },
          confidence: { type: 'string', enum: ['high', 'medium', 'low'] },
          verdict: { type: 'string', enum: ['confirmed', 'disputed', 'severity_adjusted', 'enhanced', 'new'], description: 'Codex validation verdict' },
          adjustedSeverity: { type: 'string', enum: ['critical', 'high', 'medium', 'low'], description: 'only if verdict is severity_adjusted' },
          rationale: { type: 'string', description: 'Codex validation rationale / code evidence' },
        },
      },
    },
  },
}

// --------------------------------------------------------------------
// Phase 1: Implement - sequential, one fork agent per bead, shared worktree.
// Each bead builds on the prior, so this is a flat ordered list, not parallel
// waves - concurrent agents editing the same worktree would conflict.
// --------------------------------------------------------------------
phase('Implement')
log(`Implementing epic ${args.epicId}: ${args.beadOrder.length} bead(s) in dependency order`)

const summaries = []
for (const beadId of args.beadOrder) {
  const prior =
    summaries.length === 0
      ? '(this is the first bead)'
      : summaries.map((s) => `- ${s.bead} [${s.status}] touched: ${s.files}`).join('\n')

  const result = await agent(
    `You are implementing ONE bead of epic ${args.epicId}, inside the git worktree at ${args.worktree}.

Steps:
1. Claim it:  ${br(`update ${beadId} --status in_progress`)}
2. Load it:   ${br(`show ${beadId} --json`)}  - implement its ## Design and satisfy every ## Acceptance item. Read the parent epic's ## Design Decisions too:  ${br(`show ${args.epicId} --json`)}
${args.domainLens ? `3. DOMAIN: if this bead touches the ${args.domainLens} domain, consult that domain's authoritative documentation or skill as the reference before writing code.\n` : ''}4. Implement the change in the worktree - the code, its tests, and the nearest AGENTS.md / docstring updates together, as one self-contained, independently testable unit. Your test files must compile against only code present at or below this bead (no forward references to later beads).
5. Verify: run THIS bead's own ## Verification commands from the JSON in step 2. If the bead lists none, fall back to the repo defaults: ${fallbackVerify.length ? fallbackVerify.map((c) => `\`${c}\``).join(', ') : '(none configured - rely on the bead\'s own checks)'}.${args.verify.generate ? ` If you modified generated sources, regenerate with \`${args.verify.generate}\` before building.` : ''} Fix trivial failures and re-run once. If a deep or structural failure remains, stop and report it as skipped rather than hacking around it.
6. On success:  ${br(`close ${beadId} --reason "<one concise line>"`)}
   On a blocking failure:  ${br(`update ${beadId} --status open --notes "SKIPPED: <what failed and why>"`)}
${CONVENTIONS}
Context - prior beads in this epic:
${prior}

Return the structured result.`,
    { label: `impl:${beadId}`, phase: 'Implement', schema: BEAD_RESULT_SCHEMA },
  )
  if (result) summaries.push(result)
}

const done = summaries.filter((s) => s.status === 'done')
const skipped = summaries.filter((s) => s.status === 'skipped')
log(`Implemented ${done.length} bead(s); skipped ${skipped.length}`)

// --------------------------------------------------------------------
// Phase 2: Commit - group the working tree into logical commits. One commit
// per logical change; each carries its own code, tests, and docs and must
// build independently.
// --------------------------------------------------------------------
phase('Commit')
const commitBuildCmds = args.verify.build ? [args.verify.generate, args.verify.build].filter(Boolean) : []
const commitReport = await agent(
  `cd to the worktree at ${args.worktree} and create logically grouped, atomic git commits for the uncommitted changes, following the git-commit (/commit) best-practice guidance below. Keep each commit tightly scoped to one coherent logical change.

Apply the /commit guidance:
- Detect style first: \`git log --oneline -20\`. Match the repo's convention (many repos use Conventional Commits: feat/fix/docs/refactor/test/build/chore/perf/ci); match its style, scope usage, and typical subject length.
- Group atomically into SELF-VERIFIABLE commits: one logical change per commit, each carrying the code, its tests, AND the nearest AGENTS.md / docstring updates together. Keep tests with the code they exercise. If the bead burndown produced a tests-only or docs-only change, FOLD it into the commit for the code it covers - never a standalone test or docs commit. Separate unrelated changes; use \`git add -p\` when a single file mixes concerns.
- Subject: \`type(scope): summary\` when the repo uses Conventional Commits (scope is the affected area), imperative mood, no trailing period, length matching the repo's recent commits.
- Body: DEFAULT TO NONE. Add a body only when it gives context the subject and diff do not - the why, or a non-obvious consequence - as one short paragraph (1-4 sentences) wrapped at 72. Do NOT walk through files/functions, enumerate tests, list alternatives considered, repeat the subject, or write a PR-description-style body.
- NEVER include: a bead ID or any bead reference (beads are local-only), item counts (tests/files/endpoints - they go stale), or non-ASCII / ANSI escape codes.
- Verify each commit with \`git show\` after creating it.
${
  args.verify.build
    ? `- Verify each commit is INDEPENDENTLY sound: for each commit oldest-to-newest, \`git checkout <sha>\` and run ${commitBuildCmds.map((c) => `\`${c}\``).join(' then ')} - every commit must pass, proving its tests compile against only the code in it and below (not a forward reference to a later commit). Return to the branch tip when done; if a commit fails, re-group so tests ride with the code they exercise, then re-verify.`
    : `- No repo build command is configured, so the per-commit independent-build check is skipped. Still \`git show\` each commit to confirm its contents and grouping.`
}
- Do NOT push, do NOT run any gs command, do NOT create branches. Only \`git add\` / \`git add -p\` and \`git commit\` on the current branch. If a pre-commit hook blocks the commit, report it - do NOT silently pass --no-verify.

Changes to group (by intent + files; no bead IDs):
${summaries.map((s) => `- ${s.summary} (files: ${s.files})`).join('\n')}

After committing, return the commit list as plain text: one line per commit "sha - subject", oldest first, plus a note of anything left uncommitted.`,
  { label: 'commit', phase: 'Commit' },
)
log('Commits created; entering review')

// --------------------------------------------------------------------
// Phase 3: Review - parallel focused-lens reviewers, each validating its OWN
// findings with Codex (adapted from /team-branch-review). Every reviewer reads
// its domain brief, inspects the epic Design Decisions and each bead's
// Goal/Design/Acceptance as the intent reference so deliberate deferrals are
// not re-disputed, reviews the committed diff, then self-validates with Codex.
// A conformance auditor (implementation vs design records) is appended only
// when args.designRecordsGlob is set; its findings are report-only.
// --------------------------------------------------------------------
phase('Review')

const conformanceReviewerPrompt = () => `You are the DECISION-DOC CONFORMANCE auditor on the review team for epic ${args.epicId}. Your job is NOT code quality - it is to catch where the committed implementation has drifted from what the design records actually decided, before it calcifies into the contract. You do NOT edit files.

Setup (work in ${args.worktree}; cd there first):
- Sources of truth: the design records matching ${args.designRecordsGlob}. Read the records the epic's beads cite, plus any whose subject the diff touches (storage/schema, execution model, deployment topology, auth, config delivery, public API). A bead refines the records, but a design record wins over a bead on conflict.
- Bead intent: ${br(`show ${args.epicId} --json`)} (its "## Design Decisions"), and each bead's Goal/Design/Acceptance (IDs ${args.beadOrder.join(', ')}).
- Scope: BASE=${BASE_EXPR}; audit \`git diff $BASE..HEAD\` and ESPECIALLY the durable CONTRACTS it introduces - exported types and interfaces, schema and queries, the names and granularity of key objects, public API shapes.

Audit in BOTH directions and collect findings:
1. Code-vs-doc: for each material design claim in the relevant records (granularity, ownership, state transitions, naming, who-talks-to-whom, deferrals), check the implementation matches. Report each divergence with: what the code does (file:line), what the doc says (record reference + a short quote), and which you believe is correct - but flag it for HUMAN reconciliation; do NOT assume the code is the side that must change.
2. Doc-vs-doc: if implementing this surfaced two records that disagree on the topic, flag that inconsistency.
3. Deferral drift: a deferral the docs describe that the code implemented anyway, or a doc-required behavior the code silently dropped.
A divergence from an INTENTIONAL, documented deferral is not a finding.

Validate with Codex ONCE (mcp__codex__codex, sandbox:"read-only", approval-policy:"never", cwd:"${args.worktree}"): pass the relevant doc excerpts + the diff + your divergences, and ask it per divergence to confirm or dispute with code-and-doc evidence, and to surface any conformance gap you missed (verdict "new"). If Codex is unavailable, keep your findings (verdict "confirmed") and note it.

Return the structured result with lens="conformance": a one-line outcome and the findings array. For each divergence: category "conformance", file = the code path:line, severity by how load-bearing the contract is, the record reference + quote in the rationale, and in suggestion state BOTH reconciliation options (change code to match the doc, OR amend the doc) WITHOUT choosing - these are escalated for a human decision and are never auto-applied.`

const reviewerPrompt = (lens) =>
  lens === 'conformance'
    ? conformanceReviewerPrompt()
    : `You are a senior code reviewer specializing in ${lens.toUpperCase()}, one of a parallel review team over epic ${args.epicId}. You review ONLY the committed diff; you do NOT edit files.

Setup (work in ${args.worktree}; cd there first):
${
  args.domainLens && lens === args.domainLens
    ? `- Lens source: there is no brief file for the ${lens} domain lens. Use that domain's authoritative documentation or skill (a matching skill, or the library's live docs) as your conformance rubric.`
    : `- Read your domain brief at ${args.briefDir}/${lens}.md and apply its criteria as your lens. If that file is not readable in this environment, proceed on your general ${lens} expertise - do not fail the review over a missing brief.`
}
- Establish the base commit: BASE=${BASE_EXPR}. Your scope is \`git diff $BASE..HEAD\` (see also \`git log --oneline $BASE..HEAD\`).
- Inspect the beads for intent (treat them as deliberate):
  - Epic Design Decisions: ${br(`show ${args.epicId} --json`)} -> read the "## Design Decisions" section.
  - Per-change intent: read each bead (IDs ${args.beadOrder.join(', ')}) and its "## Goal", "## Design", and "## Acceptance Criteria".
  Use these as the reference for what each change is supposed to do. If a finding merely contradicts an intentional decision recorded in the epic or a bead (a deliberate deferral or tradeoff), DROP it or mark it a tradeoff to re-examine - do not report a deliberate choice as a defect.${lens === 'correctness' ? " The correctness lens should additionally check the code actually satisfies each bead's Acceptance Criteria." : ''}

Step 1 - Primary review (coverage first): for each changed file in your lens, read the diff AND the surrounding code (Read/Grep/Glob - do not just skim the diff; trace callers/deps). Collect ALL findings, including uncertain and low-severity ones - coverage is the goal here; the Codex step filters. Tag each with severity (critical/high/medium/low), a category, and your confidence.

Step 2 - Codex self-validation: call mcp__codex__codex ONCE with sandbox:"read-only", approval-policy:"never", cwd:"${args.worktree}". Pass it the epic's Design Decisions + relevant bead intent (as intent), your Step-1 findings, and your domain criteria. Ask Codex, for EACH finding, to examine the actual code and return a verdict - Confirmed | Disputed | Severity Adjusted | Enhanced - with confidence, code-evidence rationale, and an adjusted severity if it changed; then to surface any ${lens} issues you missed (verdict "new"). A finding that contradicts an intentional design decision is not a defect. If Codex is unavailable, keep your Step-1 findings (verdict "confirmed") and note Codex was unavailable.

Step 3 - Return the structured result: lens="${lens}", a one-line outcome, and the findings array - for each finding the final severity, category, issue, file:line, a concrete suggestion, your confidence, the Codex verdict, adjustedSeverity (only if changed), and the validation rationale. Include DISPUTED findings too (verdict "disputed") so synthesis can bucket them. Report nothing about files outside your lens.`

const lenses = [...args.reviewLenses, ...(args.domainLens ? [args.domainLens] : []), ...(args.designRecordsGlob ? ['conformance'] : [])]
const reviews = (
  await parallel(lenses.map((lens) => () => agent(reviewerPrompt(lens), { label: `review:${lens}`, phase: 'Review', schema: FINDINGS_SCHEMA })))
).filter(Boolean)

// Synthesis - bucket by Codex verdict, compute outcome (/team-branch-review rules).
const allFindings = reviews.flatMap((r) => (r.findings || []).map((f) => ({ ...f, lens: r.lens })))
const effSeverity = (f) => (f.verdict === 'severity_adjusted' && f.adjustedSeverity ? f.adjustedSeverity : f.severity)
const confirmed = allFindings.filter((f) => f.verdict !== 'disputed')
const disputed = allFindings.filter((f) => f.verdict === 'disputed')
const criticalHigh = allFindings.filter((f) => effSeverity(f) === 'critical' || effSeverity(f) === 'high')
const disputedCH = criticalHigh.filter((f) => f.verdict === 'disputed')
const confirmedCH = criticalHigh.filter((f) => f.verdict !== 'disputed')
let outcome = 'APPROVED'
if (criticalHigh.length > 0 && disputedCH.length > criticalHigh.length / 2) outcome = 'MANUAL REVIEW REQUIRED'
else if (confirmedCH.length > 0) outcome = 'NEEDS REVISION'
// Conformance findings (code vs design records) are report-only: a divergence
// needs human reconciliation (the fix may be a doc edit, not a code edit), so
// they are never auto-applied and a confirmed one escalates the outcome.
const conformanceFindings = allFindings.filter((f) => f.lens === 'conformance')
const conformanceDivergences = conformanceFindings.filter((f) => f.verdict !== 'disputed')
if (conformanceDivergences.length > 0) outcome = 'CONFORMANCE DIVERGENCE - RECONCILE BEFORE MERGE'
// Auto-apply CONFIRMED findings (any severity), EXCEPT conformance (report-only);
// report disputed only.
const actionable = confirmed.filter((f) => f.lens !== 'conformance')
log(`Review: ${allFindings.length} finding(s) - ${confirmed.length} confirmed (${confirmedCH.length} crit/high), ${disputed.length} disputed, ${conformanceDivergences.length} conformance divergence(s); outcome ${outcome}`)

// --------------------------------------------------------------------
// Phase 4: Fix - auto-apply Codex-confirmed findings, then FOLD each fix into
// the commit that introduced the code (fixup + autosquash, modeled on
// /team-branch-fix's "fixup into original commits" auto-mode). The phase ends
// with clean per-unit commits and an EMPTY working tree. Disputed findings are
// reported, never auto-applied. Conformance divergences are likewise never
// auto-applied - they are reconciled by hand.
// --------------------------------------------------------------------
phase('Fix')
let fixReport = 'No confirmed findings; no fixes applied.'
if (actionable.length > 0) {
  fixReport = await agent(
    `cd to ${args.worktree}. Apply fixes for these Codex-confirmed review findings, then fold each fix into the commit that introduced the code it touches, ending with clean per-unit commits and NO uncommitted changes. Model this on /team-branch-fix's "fixup into original commits" auto-mode.

Procedure:
1. BASE=${BASE_EXPR}.
2. Apply the fixes in the working tree. Leave DISPUTED findings untouched.${args.verify.generate ? ` If a fix touches GENERATED code, fix the source and REGENERATE with \`${args.verify.generate}\` rather than hand-editing, so it cannot drift.` : ''}
3. For EACH fix, find the commit that introduced the touched code: \`git log --oneline $BASE..HEAD -- <file>\` (and \`git blame\` for the lines). Stage ONLY that fix's files (\`git add <files>\`) and create a fixup: \`git commit --fixup=<target-sha>\`. Repeat per fix.
4. Fold the fixups into their parents: \`GIT_SEQUENCE_EDITOR=true git rebase -i --autosquash $BASE\`.
   - If the rebase fails (conflicts or otherwise): \`git rebase --abort\`, then \`git reset --soft $BASE\` and create ONE summary fix commit matching the repo commit conventions, so the tree still ends clean. Note in your report that the fold-in fell back to a single commit.
5. Confirm \`git status --porcelain\` is EMPTY, then run final verification on the rebased HEAD: ${fallbackVerify.length ? fallbackVerify.map((c) => `\`${c}\``).join(', ') : '(no repo verification commands configured; confirm the tree is sound by inspection)'}.

Do NOT push and do NOT run any gs command - only local git (add/commit/rebase). The branch must end with clean per-unit commits (fixes folded in) and a clean working tree.
${CONVENTIONS}
Confirmed findings:
${JSON.stringify(actionable, null, 2)}

Return: what you changed, whether autosquash succeeded or fell back to a single commit, the final commit list (\`git log --oneline $BASE..HEAD\`), explicit confirmation the working tree is clean, and the final verification result (pass/fail per command).`,
    { label: 'fix', phase: 'Fix' },
  )
}

// --------------------------------------------------------------------
// Return a structured report for the /implement-workflow skill to act on
// (post-run sanity check, epic status resolution, PR description generation).
// --------------------------------------------------------------------
return {
  epic: args.epicId,
  beads: { done: done.map((s) => s.bead), skipped: skipped.map((s) => ({ bead: s.bead, why: s.summary })) },
  beadSummaries: summaries,
  commits: commitReport,
  review: {
    outcome,
    total: allFindings.length,
    confirmed: confirmed.length,
    disputed: disputed.length,
    conformance: conformanceFindings,
    byLens: reviews.map((r) => ({ lens: r.lens, outcome: r.outcome, n: (r.findings || []).length })),
    findings: allFindings,
  },
  fixes: fixReport,
  discoveries: summaries.map((s) => ({ bead: s.bead, discoveries: s.discoveries })).filter((d) => d.discoveries && d.discoveries !== 'none'),
}
