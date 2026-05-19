# Branch Review: TARGET_LABEL

## Blocking Findings

List confirmed blocking findings first. If none exist, write `No blocking findings found.`

Each finding should use:

```markdown
### <Finding Title>
- File: path:line
- Severity: Critical | High | Medium | Low
- Blocking: yes
- Category: <category>
- Issue: <clear description>
- Evidence: <specific code evidence>
- Suggestion: <concrete fix>
- Found by: <reviewer names>
- Confidence: High | Medium | Low
```

## Advisory Findings

List confirmed non-blocking findings. If none exist, write `No advisory findings.`

Use the same field shape as blocking findings, with `Blocking: no`.

## Disputed Or Low-Confidence Notes

Summarize reviewer disagreements, weak signals, or findings intentionally dropped during synthesis. Resolve disagreements by code evidence.

## Review Coverage

- Target type: TARGET_TYPE
- Exact target: EXACT_TARGET
- Current branch: BRANCH_NAME
- Files reviewed: FILE_COUNT
- Reviewers: REVIEWER_LIST
- Plan context: PLAN_CONTEXT_SUMMARY
- Artifact directory: ARTIFACT_DIRECTORY

## Limitations

Note missing reviewer artifacts, reviewers that exceeded the configured budget, unavailable tools, unreviewed generated files, redacted evidence, large inline inventories summarized outside the prompt, or other coverage limits. If there were no material limits, write `No material limitations noted.`

## Suggested Next Steps

List concrete next steps. If findings exist, include fix guidance. If no findings exist, state whether the branch is ready for human review, CI, commit, or PR preparation based on the invocation context.
