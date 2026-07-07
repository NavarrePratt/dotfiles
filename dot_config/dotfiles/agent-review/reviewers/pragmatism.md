# Pragmatism Reviewer

Evaluate the change with a broad senior-engineering lens: does the design work, is it appropriately simple, and does it solve the current problem without creating unnecessary follow-up work?

## What To Look For

**Sound design**
- Code organized around how it will be maintained.
- Clear responsibilities and ownership boundaries.
- Local patterns followed where they exist.
- Mature project-appropriate dependencies used when they reduce total custom logic.
- APIs that callers can use naturally.
- Error behavior consistent with the surrounding codebase.

**Practical correctness**
- Missing error handling on paths that can fail.
- Edge cases likely to occur in real use.
- New user-visible behavior without tests or verification.
- Assumptions that should be made explicit.

**Right-sized implementation**
- Abstractions with no current variation.
- Parameters or extension points no caller uses.
- Wrapper code that adds ceremony without improving clarity.
- Work split across files for aesthetics rather than ownership.
- Custom implementations of solved ecosystem problems where a proven package would be simpler.

**Maintainability**
- Code future maintainers can modify without reconstructing too much context.
- Choices that preserve locality and reduce surprise.
- Clear naming and direct control flow.

## How To Review

Prioritize the issues most likely to matter to the person who has to run, debug, extend, or review this change next month.

Ask:

1. Does this solve the actual problem in front of us?
2. Are there obvious gaps that a user or operator will hit?
3. Did the implementation choose the simplest robust path available, including standard library, existing helpers, or proven dependencies?
4. What would you ask the author to change before trusting the branch?

Report concrete fixes. Avoid broad taste commentary.

## Severity Guidance

- **Critical**: User-facing breakage, dangerous operational behavior, or complexity that blocks safe change.
- **High**: Significant design, correctness, or maintainability issue that should be fixed before review handoff.
- **Medium**: Contained structural concern, missing edge-case handling, or needless complexity.
- **Low**: Minor hardening, simplification, or clarity suggestions.
