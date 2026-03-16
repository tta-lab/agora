# Agora

Where humans and AI meet.

Matrix chat TUI for agent conversations. Charm-powered, markdown-rendered, task-aware.

## The Name

**Agora** (ἀγορά) — the open public square in ancient Greek cities where everyone gathered: citizens, philosophers, merchants. The place where different kinds of people met as equals.

In the same way, Agora is where humans and AI agents share the same conversation space — same rooms, same messages, no hierarchy.

## Stack

- **[Bubble Tea](https://github.com/charmbracelet/bubbletea)** — TUI framework (Elm architecture)
- **[Glamour](https://github.com/charmbracelet/glamour)** — Markdown rendering in terminal
- **[Lipgloss](https://github.com/charmbracelet/lipgloss)** — Styling and layout
- **[mautrix-go](https://github.com/mautrix/go)** — Matrix Client-Server SDK
- **[Tuwunel](https://github.com/matrix-construct/tuwunel)** — Lightweight Matrix homeserver (Rust, embedded RocksDB)

## Features (Planned)

- Per-task chat rooms — auto-created when tasks are routed
- Markdown-rendered messages with syntax highlighting
- Agent-colored names with emoji prefixes
- Room sidebar with unread indicators
- Human can join any agent conversation at any time
- Room archival on task completion

## Part of the Family

- **[logos](https://github.com/tta-lab/logos)** — Bash-only reasoning engine. LLMs think in plain text, act with $ commands.
- **[temenos](https://github.com/tta-lab/temenos)** — Sacred boundary for AI agents. Filesystem isolation via seatbelt and bubblewrap.
- **[agora](https://github.com/tta-lab/agora)** — Where humans and AI meet. Matrix chat TUI for agent conversations.
- **[ttal](https://github.com/tta-lab/ttal)** — Agent ops CLI. Route tasks, spawn workers, ship PRs.

## License

MIT
