# Open questions — Riverpod migration

> These points must be decided before or during Phase 0. They impact the entire migration.
> See [01_migration_plan.md](./01_migration_plan.md) for the full plan.

---

### Q1: Granularity of DataSource interfaces for the Matrix SDK

The GUIDELINES suggest ISP (segregated interfaces: `AuthClient`, `MessagingClient`, `RoomClient`). But the Matrix SDK exposes a single `Client` object that does everything.

**Options:**

- (A) A single `matrixClientProvider` that exposes the `Client` as-is, and DataSource Impl use it directly
- (B) Segregated interfaces by domain, each DataSource receives only the interface it needs

Option (B) is cleaner but creates a lot of boilerplate to wrap an SDK that was not designed for this. Does the testability gain justify the cost?

**Recommendation**: start with option (A), let segregated interfaces emerge naturally from DataSource Impl as modules are developed. Do not design central interfaces upfront.

---

### Q2: Migrating Interactors — rename or rewrite?

Current interactors use `Stream<Either<Failure, Success>>`. The GUIDELINES want `Future<T>` + typed exceptions.

**Options:**

- (A) Rewrite each interactor when migrating the module
- (B) Create new UseCases alongside the old Interactors, delete the old ones once all consumers are migrated

Option (B) avoids breaking legacy consumers but temporarily doubles the code.

---

### Q3: Feature-first vs refactoring folder structure

The GUIDELINES define a `features/xxx/{data,domain,presentation}` structure. The current code is organized as `lib/{data,domain,presentation}/xxx`. Should the folder structure be migrated at the same time as Riverpod, or is this a separate effort?

**Recommendation**: separate effort. Mixing file reorganization and pattern migration in the same PRs is a recipe for hellish merge conflicts and unreviable PRs.

---

### Q4: Architectural criterion for "done"

How do we know the migration is complete? Removing `getIt` is observable, but not sufficient. Controllers with 15 injected providers would reproduce the same problem as `chat.dart` at a different level of abstraction.

**Proposed criteria:**

- Zero `getIt` import in the codebase
- Zero `StatefulWidget` with business logic (`setState` only for pure UI)
- Zero `FutureBuilder` / `StreamBuilder` in views
- Each Controller testable via `ProviderContainer` without a widget tree
- Controller test coverage >= 80%
