# Herdr customization

This directory is the chezmoi source for `~/.config/herdr`. Edit source files,
then preview and apply only the affected targets with an explicit `--source`.
Manage related Codex hooks and helpers in their corresponding source paths.
Reconcile settings changed in Herdr before the next apply. Keep logs, sockets,
locks, sessions, and other runtime state out of Git.

## Design preferences

- Prefer locally maintained code over small, lightly adopted third-party plugins.
  Use community projects as design references.
- Prefer compact sidebar summaries and on-demand detail views. Minimize persistent
  panes and never open a pane per subagent.
- Show subagent activity in one aggregate view, including starting, working,
  completed, and stopped states when supported by reliable evidence.
- Keep the hotkey reference specific to Herdr.
- Compare custom implementation and maintenance costs against adopting Luvus.
  Custom code is welcome when it improves the workflow enough to justify its upkeep.
- Focus on agent activity, session usage/cost, and repository/GitHub status.
  Orchestration boards, network/resource monitoring, and scratch panes are out of scope.

- Keep detailed Git status out of workspace sidebar rows. Bind future Git views
  to an explicit pane checkout; use shell-prompt context and `git status --short
  --branch` as presentation references. Session usage is useful in agent rows.
