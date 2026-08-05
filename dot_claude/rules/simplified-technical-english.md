# Simplified Technical English

Apply this guidance when you create, rewrite, or review human-facing technical writing. This includes code comments, documentation, runbooks, pull request and issue text, troubleshooting procedures, and user-requested write-ups, explanations, or summaries. Do not apply it to routine conversational replies, progress updates, planning notes, or tool narration unless the user asks you to turn that content into polished human-facing prose.

Make technical text clear for a reader who did not observe the work. Preserve technical correctness before simplifying the language.

## Set the Editing Contract

1. Identify the audience, purpose, and requested artifact.
2. Identify facts that must not change: requirements, permissions, limits, sequence, evidence, and uncertainty.
3. Preserve exact identifiers, commands, paths, API names, code symbols, units, log messages, and quoted interface text.
4. Use repository terminology and project glossaries when they exist.
5. If an ambiguity changes the result, identify it instead of guessing.

When the user requests a review, report problems without changing the source. When the user requests a rewrite, return the revised artifact unless they also request commentary.

## Organize the Information

- Lead with the result, change, or finding.
- Present supporting detail in the order that the reader needs it.
- Give each paragraph one topic and no more than six sentences.
- Use a vertical list when a sentence would contain several items or actions.
- Number steps when order matters.
- Keep list items at the same logical level and in the same grammatical form.

## Use Controlled Language

- Prefer familiar, precise words over jargon, slang, idioms, and figurative language.
- Use one term for one component, service, state, or result.
- Write an official term in full on first use, then use its approved short form.
- Give each sentence one primary topic and an explicit subject, verb, and object when applicable.
- Use active voice when the actor is known and relevant.
- Use simple verb forms when they preserve the meaning.
- Put a necessary condition before the action that depends on it.
- Use pronouns only when each referent is clear.
- Use American English unless the project specifies another standard.

Example:

> Authentication now recovers from an expired token. The client refreshes the token once, and the end-to-end test passes.

Avoid:

> Resolved: auth failure -> refresh path -> green.

## Write Procedures

- Use the imperative form.
- Give one instruction per sentence unless actions must occur at the same time.
- Keep each procedural sentence to 20 words or fewer when technical accuracy permits.
- Put prerequisites and conditions before commands.
- Put a limit, expected result, or acceptance criterion next to its action.
- Separate an ordered procedure into numbered steps.

## Write Descriptions and Summaries

- Keep each descriptive sentence to 25 words or fewer when technical accuracy permits.
- Repeat a key term when repetition prevents ambiguity.
- Use connecting words only when they clarify cause, contrast, sequence, or result.
- State verified results as verified results.
- Label assumptions, uncertainty, and unfinished work directly.

## Protect Normative and Safety Meaning

- Preserve the difference between a requirement, recommendation, permission, and possibility.
- Preserve the sequence of operations and all stated limits.
- Use `WARNING` for a risk of injury or death.
- Use `CAUTION` for a risk to equipment, software, data, or other property.
- State the preventive action, the hazard, and the possible result in each safety instruction.
- Use a note only for supporting information, never for a required action, limit, result, or safety instruction.

## Write Code Comments

- Explain behavior, intent, or a non-obvious constraint.
- Preserve symbol names exactly.
- Do not restate syntax that the code already makes clear.
- State test results or progress only when current evidence supports the claim.

## Check the Result

Before finishing, verify that:

- The opening sentence states the outcome or purpose.
- Technical meaning and normative force are unchanged.
- Exact terms, identifiers, commands, units, and quoted text remain intact.
- Conditions appear before dependent actions.
- Sentences have clear actors and actions.
- Procedures remain ordered, bounded, and testable.
- Claims distinguish evidence from assumptions.
- The result contains complete prose instead of working shorthand.
