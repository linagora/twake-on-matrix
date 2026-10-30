# Riverpod migration status

Plan: [docs/migration/04_plan_v2.md](docs/migration/04_plan_v2.md) ·
Rules: [ADR 0037](docs/adr/0037-riverpod-migration-rules.md)

A pull request may not increase the first table: the `Riverpod migration`
workflow compares it with the base branch and shows both in its summary. Run
`scripts/migration_status.sh` for live numbers.

The tables below are a snapshot, refreshed with
`scripts/migration_status.sh --write` on an up-to-date `main`. A pull request
updates only the Modules table.

<!-- metrics:begin -->
_Measured on 2026-10-21 by `scripts/migration_status.sh --write`._

| Metric | Count |
|---|---:|
| `Matrix.of` / `Matrix.read` calls | 288 |
| `getIt` uses, bridges included | 347 |
| `getIt.register*` calls | 145 |
| `Stream<Either<…>>` | 56 |
| Files importing `dartz` | 121 |
| Files in `lib/domain/app_state/` | 70 |
| UI files importing `package:matrix` | 327 |

| Progress | Count |
|---|---:|
| `getIt` uses in `*.provider.dart` bridges | 0 |
| `@riverpod` providers | 26 |
| Notifier classes | 7 |
| Consumer widgets | 19 |
| `StatefulWidget`s | 152 |
<!-- metrics:end -->

## Modules

| Module | Status | Pull request |
|---|---|---|
| contacts_invitation | Controller, still on legacy interactors | #3233 |
| bootstrap, verify_device | Controllers | #3292 |
| device_settings | Controller, still on `app_state` | #3389 |
| contacts | In review | #3459 |
| reactions | Use cases + native providers, GetIt removed | #3527 |
| capabilities | Use case + native providers, GetIt removed | |
| Everything else | Legacy | |
