# 36. Release Process

Date: 2026-04-22

## Status

Accepted

## Context

The project ships to multiple platforms (Android Play Store internal track, iOS TestFlight, Docker Hub). A reproducible, documented release process is needed so any team member can cut a release consistently.

## Decision

### 1. Ensure main branch is ready

All feature/fix commits that are intended for the release must be merged into `main` before starting the release process. No half-merged PRs or WIP commits should be present.

### 2. Pull translations from Weblate

Weblate pushes translation commits to the `weblate/l10n` remote branch (tracked locally as `l10n`). Cherry-pick or merge those commits into `main`:

### 3. Update CHANGELOG.md

Follow the format already established in the file:

```text
## [x.y.z] - YYYY-MM-DD
### Added
- TW-XXXX: Short description, < 80 chars per line

### Changed
- TW-XXXX: Short description, < 80 chars per line

### Fixed
- TW-XXXX: Short description, < 80 chars per line
```

Rules:
- Group all commits that share the same ticket ID (`TW-XXXX`) into **one** line item.
- Lines must be ≤ 80 characters. Wrap onto a second line only if absolutely necessary; never more than 2 lines per item.
- Weblate translations → single entry under `### Added`: `Translated using Weblate (…languages…)`
- Commits without a ticket ID use a short imperative phrase (same ≤ 80 chars, ≤ 2 lines rule).

### 4. Bump version

Edit **`pubspec.yaml`** — `version: x.y.z+2330`:
- `x.y.z` matches the new release tag.
- `2330` (the integer after `+`) is managed by CI/CD. Don't touch it.


Then commit **only** the version bump and the CHANGELOG update together in a dedicated commit:

```bash
git add CHANGELOG.md pubspec.yaml
git commit -m "chore: bump version to vx.y.z"
```

### 5. Create and push the tag

Tag format: `vMAJOR.MINOR.PATCH` (stable) or `vMAJOR.MINOR.PATCH-rcNN` (release candidate).

Examples: `v2.21.7`, `v2.21.7-rc01`

```bash
git tag vx.y.z
git push origin main.                  # stable
# or: git tag vx.y.z-rcNN              # release candidate
git push origin refs/tags/vx.y.z.      # stable
# or: git push origin refs/tags/vx.y.z-rcNN
```

Pushing a tag that matches `v*.*.*` triggers **both** automated workflows (see §6).

### 6. Automated CI/CD workflows triggered by the tag

| Workflow file | Trigger | What it does |
|---|---|---|
| `.github/workflows/release.yaml` | `push: tags: v*.*.*` | Builds signed Android APK + AAB → Play Store internal track; builds iOS IPA → TestFlight; creates GitHub Release with artifacts and SHA256 checksums |
| `.github/workflows/image.yaml` | `push: tags: v*.*.*` | Builds multi-arch Docker image (`linux/amd64`, `linux/arm64`), pushes to Docker Hub (`linagora/twake-web`) and GHCR (`ghcr.io/linagora/twake-web`) tagged with the version and `release` |

The `release.yaml` job runs mobile builds in parallel (Android on `ubuntu-latest`, iOS on `macos-26`) and creates the GitHub Release only after both succeed.

### 7. Post-release deployment

Once CI is green:

| Platform | Action |
|---|---|
| **TestFlight** | Auto-uploaded by Fastlane in `release.yaml`; promote to App Store via App Store Connect |
| **Play Store** | Uploaded to internal track by Fastlane; promote to alpha/beta/production in Play Console |
| **Docker / GHCR** | Image tagged with `vx.y.z` and `release` is ready; update deployment manifests / Helm values to the new tag |

## Consequences

- Every release has a single source of truth: the git tag.
- CHANGELOG entries are human-readable and ticket-traceable.
- Translations are always included before tagging, eliminating separate "translation release" tags.
- The version bump commit is isolated, making rollbacks and bisect easy.
- No manual upload steps are needed for mobile stores or Docker; CI handles everything after the tag is pushed.
