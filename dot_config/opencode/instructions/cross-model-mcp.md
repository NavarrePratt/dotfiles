# Cross-Model MCP Tools (OpenCode-specific)

You have two MCP servers for cross-family adversarial review:

- **codex** (`mcp__codex__codex`): GPT-5.5. Use when you need a GPT opinion on your work.
- **cross-agent** (`claude_prompt` / `claude_continue` / `claude_abort`): Claude. Use when you need a Claude opinion on your work.

The `cross-agent_opencode_*` tools are disabled in your config to prevent
recursion (you ARE opencode). Do not attempt to call them.

When using cross-model MCP tools:
- Do not manually specify the `model` parameter unless the user explicitly requests a specific model. Let each backend use its configured default.
- `read_only=True` is the default and correct for adversarial review.
- Do not paste large diffs or file contents into the prompt. The reviewing agent has read-only tools (Read, Glob, Grep, WebFetch) and can read files itself. Give it the working directory or file paths to review and let it explore on its own. This keeps prompts short and lets the reviewer form its own understanding.
- Use `claude_prompt` when the user asks for a Claude opinion or review.
- Use `codex` when the user asks for a Codex/GPT opinion or review.
- For non-trivial cross-model calls (full reviews, multi-file analysis), dispatch the MCP call inside a subagent so the main conversation isn't blocked. For trivial calls (quick question, one-liner check), call the MCP tool directly.
- For session continuation, pass the returned `session_id` to the matching `_continue` tool.
