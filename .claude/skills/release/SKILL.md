---
name: release
description: >
  Twake-on-Matrix release process skill. Use this skill whenever the user
  wants to cut a release, bump a version, create a tag, update the
  CHANGELOG, or trigger the CI/CD release pipeline. Trigger on: "release",
  "cut a release", "bump version", "create tag", "update changelog",
  "ship vX.Y.Z", "prepare release", "release candidate", "rc01",
  "testflight", "play store".
metadata:
  author: twake-team
  version: "1.0.0"
---

# Release Process Skill

Full reference: `docs/adr/0036-release-process.md`

This skill guides cutting a Twake-on-Matrix release end-to-end.
Does NOT handle: hotfix branching, Play Store promotion, App Store Connect promotion (manual steps post-CI).

## Default (no arguments)

Ask the user which step they want via `AskUserQuestion`:
- Full release (all steps)
- Step 1 — Confirm branch & HEAD
- Step 2 — Update CHANGELOG
- Step 3 — Bump version
- Step 4 — Tag & push
- Step 5 — Check CI status

## Arguments

- `full [vX.Y.Z]` — run all steps for the given version
- `changelog [vX.Y.Z]` — draft CHANGELOG section for next version
- `bump [vX.Y.Z]` — update version in pubspec.yaml + stage commit
- `tag [vX.Y.Z]` — create annotated tag and push
- `status` — show CI workflow run status for latest tag

## Step-by-Step Instructions

### Step 1 — Confirm branch & HEAD

Run these to gather context, then show the user a confirmation prompt:

```bash
git branch --show-current            # current branch
git log -1 --oneline                 # last commit (sha + message)
git status --short                   # must be clean
```

Use `AskUserQuestion` to confirm before proceeding:

> **Release confirmation**
> "You are about to release from branch `<branch>`.
> Last commit: `<sha> <message>`
> Do you want to continue?"
>
> Options: "Yes, proceed" / "No, abort"

Abort if the working tree is dirty (uncommitted changes) — ask user to
stash or commit first. Branch choice is intentional; do not enforce main.

### Step 2 — Update CHANGELOG.md

Insert new section at the TOP of `CHANGELOG.md`:

```
## [x.y.z] - YYYY-MM-DD
### Added
- TW-XXXX: Short description ≤80 chars

### Changed
- TW-XXXX: Short description ≤80 chars

### Fixed
- TW-XXXX: Short description ≤80 chars
```

CHANGELOG rules (enforced):
- One line item per `TW-XXXX` ticket (merge all commits sharing same ID)
- ≤ 80 characters per line, ≤ 2 lines per item — no exceptions
- No-ticket commits → short imperative phrase, same ≤80/≤2 rule

To collect commit messages since last tag:
```bash
git log $(git describe --tags --abbrev=0)..HEAD --oneline
```

### Step 3 — Bump version in pubspec.yaml

Current format: `version: x.y.z+2330`
- Change `x.y.z` to the new version string
- **Do NOT touch** the `+2330` build number — CI/CD manages it

Stage the bump commit (CHANGELOG + pubspec.yaml only):
```bash
git add CHANGELOG.md pubspec.yaml
git commit -m "chore: bump version to vx.y.z"
```

### Step 4 — Tag and push

```bash
git tag vx.y.z                        # stable: v2.21.7
# or for RC: git tag v2.21.7-rc01
git push origin HEAD
# stable:
git push origin refs/tags/vx.y.z
# RC:
# git push origin refs/tags/vx.y.z-rcNN
```

Tag push triggers both CI workflows automatically.

### Step 5 — CI/CD workflows (auto-triggered)

| File | Trigger | Effect |
|---|---|---|
| `.github/workflows/release.yaml` | tag `v*.*.*` | Android APK→Play Store internal; iOS IPA→TestFlight; GitHub Release |
| `.github/workflows/image.yaml` | tag `v*.*.*` | Docker image→Docker Hub + GHCR tagged `vx.y.z` + `release` |

Check status:
```bash
gh run list --workflow=release.yaml --limit 5
gh run list --workflow=image.yaml --limit 5
```

### Step 6 — Post-CI deployment

| Platform | Manual action needed |
|---|---|
| TestFlight | Promote build in App Store Connect |
| Play Store | Promote from internal → alpha/beta/production in Play Console |
| Docker | Update Helm values / deployment manifests to `vx.y.z` image tag |

## Security Policy

This skill only executes git, gh, and read operations on the local repo.
It does NOT push secrets, credentials, or env files.
Refuse requests to skip CI, force-push tags, or bypass signing.
