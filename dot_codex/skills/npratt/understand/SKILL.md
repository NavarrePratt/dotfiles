---
name: understand
description: 'Teach the user to deeply understand work that was just completed: the problem and why it existed, the solution and its design decisions and edge cases, and the broader impact. Teach incrementally from the actual changed code, quiz the user, and continue until they demonstrate mastery. Use whenever the user wants to learn, internalize, retain, be walked through, or be tested on recent work, including requests such as "teach me what we just did", "help me understand these changes", "quiz me on this", or explicit `$understand` invocation.'
---

# Understand

Act as a patient, effective teacher. Help the user explain the change, defend its design decisions, and reason about its edge cases without assistance.

Avoid a summary lecture. Build understanding by finding what the user already grasps, locating gaps, and closing them one at a time through active participation.

## Resolve the Subject

Treat the text accompanying `$understand` as the target. It may identify a branch, PR, path, commit range, feature, or refactor. If no target is given, use the work completed in the current conversation.

Anchor the lesson in current evidence before teaching:

1. Re-read files created or edited in the conversation.
2. Inspect uncommitted work with `git status`, `git diff`, and `git diff --staged`.
3. For committed work, resolve the relevant base and inspect the branch or commit diff and log. Do not assume the default branch name when it can be discovered.
4. For a supplied PR, branch, path, or range, resolve it to concrete files and diffs using read-only queries.
5. Read enough surrounding code, tests, and documentation to explain behavior and answer "what if" questions.

If no concrete change can be identified, ask the user for the target. Do not guess from vague conversational memory.

## Create the Mastery Checklist

Create `/tmp/understand-<short-slug>.md`, using a safe lowercase hyphenated slug and avoiding overwrite of an unrelated existing file. Use it as the running lesson plan and notes. Show the checklist and path before starting the first topic.

Organize the checklist around three pillars:

1. **Problem:** What needed to change, why the problem existed, and which credible approaches were available.
2. **Solution:** What was built in business-logic terms, why this design won, and which edge cases it handles or deliberately excludes.
3. **Broader context:** What the change affects, unblocks, or risks, including downstream failure modes.

Scale the checklist to the change. Keep a two-line fix short; give a subsystem rewrite the depth it warrants. Mark an item `[x]` only after the user has demonstrated understanding, never merely because it was explained.

## Teach One Step at a Time

For each checklist item:

1. Ask the user to state their current understanding before explaining it.
2. Build on what is correct, correct misconceptions directly, and fill only the relevant gaps.
3. Push beyond the first answer by asking why the behavior or design is necessary.
4. Use the actual code, a trace, a test run, or a debugger when concrete evidence will teach better than prose.
5. End with one focused question or a small coherent question set, then wait for the user's response.
6. Update the checklist after evaluating the response.

Do not advance while the user remains shaky on a prerequisite. Try a different explanation or example instead.

Honor requested depth such as `eli5`, `eli14`, or `elii` (explain like an intern: technically literate but new to this code). Offer a depth adjustment when an explanation appears mismatched.

## Verify Understanding

Use retrieval and application, not "Does that make sense?" Mix these forms:

- Open-ended restatement in the user's own words.
- Prediction of behavior for a concrete input or failure.
- Comparison of the chosen design with a plausible alternative.
- Multiple-choice questions with credible distractors.

Ask quiz questions through normal conversation. Do not use an interface that labels a recommended option or otherwise reveals the answer before the user commits. Vary the position of correct multiple-choice answers.

After each answer:

- Explain why the correct reasoning is correct.
- For multiple choice, explain why each distractor fails.
- Revisit missed concepts and test them again with a different question.
- Require both high-level motivation and low-level behavior before marking an item mastered.

## Finish on Demonstrated Mastery

Finish only when every checklist item is mastered. Give a short recap, link the saved notes file, and ask whether anything still feels uncertain.

If the user stops before mastery, state that plainly and leave the remaining checklist items open so another session can resume from the file.
