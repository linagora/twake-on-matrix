# Patrol Test Guide

This guide explains how to run this project’s **Patrol** integration tests and how to configure the environment.

## 1) Prerequisites

- **Patrol** installed and working on your machine. See official docs for setup instructions: https://patrol.leancode.co/documentation
- **Flutter SDK**: use the **same version** as the application you’re testing.
- **Version compatibility**: make sure `patrol_cli`, the `patrol` Dart package, and your **Flutter** version are compatible: https://patrol.leancode.co/documentation/compatibility-table
- A valid **`.env.local.do-not-commit`** file with credentials and runtime configuration.

> **Why this matters**: Mismatched versions between the app’s Flutter SDK, the `patrol` package, and the Patrol CLI are a common source of failures.

## 2) Environment configuration

Create `integration_test/.env.local.do-not-commit` (not tracked by Git). Example keys used by scripts:

```bash
# Device configuration used by the run command below
DEVICE=iPhone 16 Pro (18.0)

# App/server runtime variables (examples)
BASE_URL=https://staging.example.com
USERNAME=john.doe@example.com
PASSWORD=secret
```

> The file’s exact keys depend on your app and scripts. At a minimum, define **`DEVICE`** so the run command can pick the simulator/emulator.

## 3) Running tests

You can run Patrol tests **directly** via the CLI or **through the provided script**.

### Option A — Run directly with Patrol CLI

The project uses an environment file and passes it to `patrol test` via `--dart-define-from-file`.

```bash
ENV_FILE=integration_test/.env.local.do-not-commit
patrol test \
  --dart-define-from-file="$ENV_FILE" \
  --device "$(grep -E '^DEVICE=' "$ENV_FILE" | cut -d= -f2-)"
```

- Without `--target`, Patrol will run **all integration tests** under `integration_test/` that end with `*_test.dart`.
- Use **`--target`** to run a specific file (you can repeat `--target` to run several files in one run).

**Examples:**

Run a **single test file**:

```bash
ENV_FILE=integration_test/.env.local.do-not-commit
patrol test \
  --target integration_test/tests/chat/chat_group_test.dart \
  --dart-define-from-file="$ENV_FILE" \
  --device "$(grep -E '^DEVICE=' "$ENV_FILE" | cut -d= -f2-)"
```

Run **multiple specific files**:

```bash
ENV_FILE=integration_test/.env.local.do-not-commit
patrol test \
  --target integration_test/tests/chat/chat_group_test.dart \
  --target integration_test/tests/chat/chat_member_test.dart \
  --dart-define-from-file="$ENV_FILE" \
  --device "$(grep -E '^DEVICE=' "$ENV_FILE" | cut -d= -f2-)"
```

Run **all tests** (default behavior — omit `--target`):

```bash
ENV_FILE=integration_test/.env.local.do-not-commit
patrol test \
  --dart-define-from-file="$ENV_FILE" \
  --device "$(grep -E '^DEVICE=' "$ENV_FILE" | cut -d= -f2-)"
```

Run **all tests located under a specific subfolder** (generate `--target` for each file in that subfolder):

```bash
SUBDIR=integration_test/tests/chat
ENV_FILE=integration_test/.env.local.do-not-commit

# Build a list of all *_test.dart files in the subfolder and pass each as a --target
patrol test \
  $(find "$SUBDIR" -name "*_test.dart" -print0 | xargs -0 -I{} printf " --target %s" {}) \
  --dart-define-from-file="$ENV_FILE" \
  --device "$(grep -E '^DEVICE=' "$ENV_FILE" | cut -d= -f2-)"
```

> Tip: if the command line gets too long (lots of files), consider splitting by module or running multiple invocations.

### Option B — Run via helper script

A convenience script is provided:

```bash
./scripts/integration_test_patrol.sh
```

- The script defaults to the **`.env.local.do-not-commit`** file under `integration_test/`.
- It supports overriding targets by passing `--target` arguments (check the script header for usage) or by editing the `-t/--target` lines inside the script.

**Example:** point the script to a **single file**:

```bash
./scripts/integration_test_patrol.sh --target integration_test/tests/chat/chat_group_test.dart
```

**Example:** point the script to **all tests in a subfolder**:

```bash
# Pass multiple --target flags (one per file)
./scripts/integration_test_patrol.sh \
  --target integration_test/tests/chat/chat_group_test.dart \
  --target integration_test/tests/chat/chat_member_test.dart
```

## 4) Version checks (quick checklist)

- `flutter --version` matches the app’s Flutter version.
- `patrol --version` (CLI) is compatible with the `patrol` package version in your `pubspec.lock`.
- Android/iOS toolchains are installed and visible to Flutter (`flutter doctor`).

## 5) Troubleshooting

- **Tests don’t start or hang**: check the `DEVICE` value and ensure the emulator/simulator can be launched.
- **Version mismatch errors**: align `Flutter`, `patrol_cli`, and `patrol` versions.
- **Missing env values**: confirm required keys exist in `.env.local.do-not-commit`.
- **Permission/native popups not handled**: verify native integration steps were completed during Patrol setup.

---

**TL;DR**
- Use `patrol test` directly or `./scripts/integration_test_patrol.sh`.
- Omit `--target` for **all tests**; use one or many `--target` flags to run **specific tests**.
- Keep Flutter + Patrol versions in sync and provide a proper `.env.local.do-not-commit`.

