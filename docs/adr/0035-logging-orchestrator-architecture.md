# 35. Logging Orchestrator Architecture

Date: 2026-03-23

## Status

Accepted

## Context

Logging was ad-hoc via Matrix SDK's `Logs()` with no central control over destinations or content sanitization.

## Decision

Introduce `LogOrchestrator` (`lib/utils/logging/`) — a singleton that runs each `LogEntry` through a **filter chain** then dispatches to a **logger chain**.

```text
log(entry) → [filters] → null = drop | entry = continue → [loggers]
```

### Key types

| File                                 | Role                                                            |
| ------------------------------------ | --------------------------------------------------------------- |
| `log_types.dart`                     | `LogLevel` (debug/info/warn/error/wtf) + `LogEntry`             |
| `logger.dart`                        | `Logger` interface — `void log(LogEntry)`                       |
| `log_filter.dart`                    | `LogFilter` interface — `LogEntry? filter(entry)` (null = drop) |
| `loggers/console_logger.dart`        | All levels → `dart:developer` / browser `console`               |
| `loggers/sentry_logger.dart`         | `wtf` only → `Sentry.captureException`                          |
| `filters/sensitive_data_filter.dart` | Redacts password/token/secret in message + context              |
| `init_matrix_logger.dart`            | Bridges Matrix SDK `Logs().onLog` into the orchestrator         |

### Initialization (`get_it_initializer.dart`)

```dart
logOrchestrator.addLogger(ConsoleLogger());
// logOrchestrator.addFilter(SensitiveDataFilter());  // TODO: enable
logOrchestrator.addLogger(SentryLogger());
```

## Consequences

- New backends: implement `Logger`, call `addLogger()` — no other changes.
- Logger exceptions are caught internally (`debugPrint`) — cannot crash the app.
- `SensitiveDataFilter` is **disabled** — credentials may appear in Sentry until enabled.
- `SentryLogger.log()` is `async` but `Logger` interface is `void` — future is fire-and-forget.
- Only `wtf` reaches Sentry; `error`-level is console-only.
