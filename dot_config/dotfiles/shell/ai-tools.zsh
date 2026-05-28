# AI CLI helpers that are not tied to legacy bd automation.

_CLAUDE_STREAM_JQ='
if .type == "system" then
  if .subtype == "init" then
    "\n\033[1;36m=== SESSION START ===\033[0m\n  Model: \(.model)\n  Tools: \((.tools // []) | length) available\n  MCPs: \((.mcp_servers // []) | map(.name) | join(", "))"
  elif .subtype == "compact_boundary" then
    "\n\033[1;33m--- CONTEXT COMPACTED ---\033[0m"
  elif .subtype == "hook_response" and .hook_name then
    "\033[2m[hook:\(.hook_name)]\033[0m"
  else empty end
elif .type == "assistant" then
  .message.content[]? |
  if .type == "text" then
    .text
  elif .type == "thinking" then
    "\033[2;3mthinking: \(.thinking | split("\n")[0] | .[0:80])\033[0m..."
  elif .type == "tool_use" then
    if .name == "Bash" then
      "\033[1;32m$ \(.input.command | split("\n")[0])\033[0m" +
      if .input.description then " \033[2m# \(.input.description)\033[0m" else "" end
    elif .name == "Read" then
      "\033[1;34mRead: \(.input.file_path)\033[0m"
    elif .name == "Edit" then
      "\033[1;33mEdit: \(.input.file_path)\033[0m"
    elif .name == "Write" then
      "\033[1;35mWrite: \(.input.file_path)\033[0m"
    elif .name == "Glob" then
      "\033[1;36mGlob: \(.input.pattern)\033[0m"
    elif .name == "Grep" then
      "\033[1;36mGrep: \(.input.pattern)\033[0m"
    elif .name == "Task" then
      "\033[1;35mAgent[\(.input.subagent_type // "task")]: \(.input.description)\033[0m"
    elif .name == "Skill" then
      "\033[1;33mSkill: \(.input.skill)\033[0m"
    elif .name == "TodoWrite" then
      "\033[1;34mTodos updated\033[0m"
    else
      "\033[1;37mTool: \(.name)\033[0m"
    end
  else empty end
elif .type == "result" then
  "\n\033[1;36m=== SESSION END ===\033[0m\n  Turns: \(.num_turns)  Duration: \((.duration_ms / 1000 / 60) | floor)m  Cost: $\(.total_cost_usd | . * 100 | round / 100)\n\033[2m\(.result // "" | split("\n") | .[0:5] | join("\n"))\033[0m"
else empty end
'

claude-stream() {
  local prompt="$1"
  local logfile="$2"

  claude --model opus --print --verbose --output-format=stream-json "$prompt" |
    tee -a "$logfile" |
    jq -r "$_CLAUDE_STREAM_JQ"
}
