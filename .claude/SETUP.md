# AI Development Setup

This document describes the Claude Code configuration for this project: agents and MCP servers available to assist development.

---

## MCP Servers

MCP (Model Context Protocol) servers extend Claude's capabilities with live tools. Configured in `.mcp.json` at the project root.

### chrome-devtools

Official MCP server by the Chrome DevTools team. Connects Claude to a running Chrome instance for browser automation and inspection.

**No installation required** — runs via `npx` automatically.

Capabilities: navigate pages, click, fill forms, take screenshots, capture network requests, read console logs, run Lighthouse audits, performance tracing.

Typical use: debugging web views, automating UI tests, inspecting Matrix client behavior in the browser.

### flutter-inspector

Unofficial MCP server by [Arenukvern](https://github.com/Arenukvern/mcp_flutter). Connects Claude to a running Flutter app via the Dart VM service.

**Requires manual setup:**

```bash
git clone https://github.com/Arenukvern/mcp_flutter
cd mcp_flutter
make install
# Then place or symlink the binary:
mkdir -p ~/tools
ln -s $(pwd)/mcp_server_dart/build/flutter_inspector_mcp ~/tools/flutter_inspector_mcp
```

Or set the `MCP_FLUTTER_BIN` environment variable to the binary path.

Run the Flutter app with VM service enabled:

```bash
flutter run --debug \
  --host-vmservice-port=8182 \
  --dds-port=8181 \
  --enable-vm-service \
  --disable-service-auth-codes
```

Capabilities: screenshots, error monitoring, widget inspection, and **dynamic tool registration** — the app itself can register custom MCP tools at runtime via the `mcp_toolkit` package.

---

## Agents

Specialized sub-agents invoked automatically by Claude when the task matches their domain. Defined in `.claude/agents/`.

### Rodin Tech

**`rodin-tech`** — Socratic sparring partner for technical decisions, architecture, and code review.

Adapted from [this original Rodin agent](https://gist.github.com/bdebon/e22d0b728abc5f393227440907b334cf) — a general-purpose Socratic interlocutor — and specialized for technical and engineering contexts: Flutter/Dart, mobile architecture, distributed systems, code review.

Rodin is not an assistant. He is a technical peer who will push back, challenge assumptions, and refuse to validate decisions just because you made them. He thinks in trade-offs, failure modes, and operational reality.

Use him when:
- You want to pressure-test an architectural decision before committing to it
- You have a PR you want torn apart before it hits review
- You're choosing between two approaches and want the honest case against each
- You suspect your mental model is wrong but can't see why

He will tell you if your abstraction is premature, your state management is over-engineered, or you're solving the wrong problem. He won't wrap it in diplomatic softening.

Invoke explicitly: `use rodin-tech to review this architecture decision`

---

### Flutter Agents

The Flutter agents come from [cleydson/flutter-claude-code](https://github.com/cleydson/flutter-claude-code), a Claude Code plugin marketplace providing a full suite of 19 specialized Flutter agents. Only a subset is included here — refer to the repo to add more.

**`flutter-architect`** — Architecture, project structure, Clean Architecture, dependency injection, navigation patterns.

**`flutter-state-management`** — State management implementation and selection: BLoC, Riverpod, Provider, GetX. Helps choose the right solution and migrate between them.

**`flutter-testing`** — Unit, widget, and integration tests. BLoC testing, mocking, TDD workflows.

**`flutter-performance-analyzer`** — Profiling and bottleneck identification: jank, memory leaks, unnecessary rebuilds, DevTools analysis.

**`flutter-performance-optimizer`** — Implements optimizations identified by analysis: const constructors, ListView.builder, RepaintBoundary, isolates.

**`flutter-device-orchestrator`** — Manages iOS simulators and Android emulators: launch, install, screenshot capture, multi-device testing.

---

### Zeus

**`zeus`** — Auditeur impartial qui vérifie les modifications de code contre le `GUIDELINES.md` du projet. Strictement ni plus ni moins que ce que le document dit.

Invocation explicite uniquement : `use zeus to review [fichier/diff/PR]`

Zeus produit un rapport détaillé dans `zeus-report.md` (non versionné, ignoré par git). Chaque violation cite la règle exacte, explique le problème, son impact, et propose une correction concrète avec une explication pédagogique. Les violations sont classées par sévérité (CRITICAL / WARNING / NITPICK) à sa propre discrétion selon le contexte.

Il ne valide pas pour faire plaisir. Si le code est propre, il le dit. Si ce n'est pas le cas, il le dit aussi.

---

### Code Quality Agents

**`code-reviewer`** — Reviews code against project guidelines and style. Invoked automatically before commits and PRs.

**`code-simplifier`** — Reduces accidental complexity in recently written code without changing behavior. Invoked automatically after significant code changes.

**`comment-analyzer`** — Verifies that comments and docstrings are accurate, complete, and won't rot. Invoked after documentation changes and before PRs.

**`silent-failure-hunter`** — Hunts for error handling that swallows exceptions, inappropriate fallbacks, and catch blocks that hide failures. Invoked after any error handling work.

**`pr-test-analyzer`** — Reviews PRs for test coverage quality and gap identification. Invoked when a PR is ready for review.

**`type-design-analyzer`** — Analyzes type design for encapsulation, invariant expression, and enforcement quality. Invoked when new types are introduced.
