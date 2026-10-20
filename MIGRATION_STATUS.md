# Riverpod migration status

Plan: [docs/migration/04_plan_v2.md](docs/migration/04_plan_v2.md) ·
Rules: [ADR 0037](docs/adr/0037-riverpod-migration-rules.md)

A pull request may not increase the first table: the `Riverpod migration`
workflow compares it with the base branch. Run `scripts/migration_status.sh`
for live numbers.

<!-- metrics:begin -->
_Measured on 2026-10-20 at `7d123675f` by `scripts/migration_status.sh --write`._

| Metric | Count |
|---|---:|
| `Matrix.of` / `Matrix.read` calls | 288 |
| `getIt` lookups outside providers | 231 |
| `getIt.register*` calls | 145 |
| `Stream<Either<…>>` | 56 |
| Files importing `dartz` | 121 |
| Files in `lib/domain/app_state/` | 70 |

| Progress | Count |
|---|---:|
| `getIt` lookups inside providers (bridges) | 8 |
| `@riverpod` providers | 26 |
| Notifier classes | 7 |
| Consumer widgets | 19 |
| `StatefulWidget`s | 152 |
| UI files importing `package:matrix` | 327 |
<!-- metrics:end -->

## Modules

| Module | Status | Pull request |
|---|---|---|
| contacts_invitation | Controller, still on legacy interactors | #3233 |
| bootstrap, verify_device | Controllers | #3292 |
| device_settings | Controller, still on `app_state` | #3389 |
| contacts | In review | #3459 |
| Everything else | Legacy | |
