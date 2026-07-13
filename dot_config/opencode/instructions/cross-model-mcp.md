# Cross-Model Review

Use the Codex and Claude tools for adversarial review and second opinions.

The `cross-agent_opencode_*` tools are disabled in your config to prevent
recursion. Do not call the current OpenCode harness through itself.

- Let each backend use its configured model unless the user explicitly requests an exact override.
- Keep reviews read-only unless the user explicitly authorizes writes.
- Do not set a timeout unless the user explicitly requests one. Backend defaults are tuned for long-running reviews.
- Give the reviewer the working directory or relevant paths and let it inspect them. Do not paste large diffs or file contents into the prompt.
- Prefer a different model family when diversity matters.
- Dispatch substantial or multi-file reviews through a subagent; make quick calls directly.
- Continue a session with its returned session ID and matching continuation tool.
