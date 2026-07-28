# Disk Cleanup Script Design

**Date**: 2026-07-28
**Status**: Approved

## Problem

The dev Mac's SSD is nearly full (Data volume: 408GB used / 48GB free, 90%
capacity). An ad-hoc investigation found the space split across many
directories with very different risk profiles: some are trivially
regenerable caches (Homebrew, Xcode DerivedData), some need care (iOS
DeviceSupport, Docker images/volumes), and some must never be touched by a
script (Draw Things AI model files, personal media in Movies/Downloads).
There's no repeatable way to re-run this investigation and act on it.

## Solution

Add `scripts/disk-cleanup.sh`, a standalone bash script (not wired into
`install.sh`) that:

1. Measures a fixed catalog of known space-heavy locations on this machine
2. Prints them sorted largest-first, matching the format used during the
   manual investigation
3. Walks through each non-report-only target interactively, showing its size
   and a one-line safety note, then prompts before acting
4. Reports space freed per target and a total summary at the end

The script is invoked manually (`./scripts/disk-cleanup.sh`); there is no
cron/launchd scheduling in this iteration.

## Target Catalog and Tiers

Each target has a `tier` that controls the prompt's default answer and
warning strength:

### `auto-safe` (prompt defaults to `Y`; deleted data is regenerated
automatically by the owning tool)

- Homebrew cache — `brew cleanup`
- Xcode DerivedData — `rm -rf ~/Library/Developer/Xcode/DerivedData/*`
- CoreSimulator unavailable devices — `xcrun simctl delete unavailable`
- Go build cache — `go clean -cache`
- pip cache — `pip cache purge`
- CocoaPods cache — `pod cache clean --all`
- node-gyp cache — clear `~/Library/Caches/node-gyp/*`

### `confirm` (prompt defaults to `N`; needs a warning because recovery takes
a manual step or the blast radius is wider than this repo)

- iOS DeviceSupport — list version subdirectories, automatically exclude the
  2 most recent versions from deletion candidates (heuristic stand-in for
  "currently in use," since reliably detecting the currently attached
  device's iOS version from a script is not dependable), then prompt
  per-version for the rest
- Playwright browser cache (`ms-playwright`, `ms-playwright-go`) — deleting
  requires manually re-running `npx playwright install` afterward; the
  prompt notes this
- Google Chrome cache (`~/Library/Caches/Google/...`, not the profile in
  Application Support) — prompt recommends closing Chrome first
- OrbStack / Docker — presented as two separate, separately-confirmed steps:
  1. `docker builder prune` (build cache only)
  2. `docker system prune -a --volumes` (all unused images/containers/
     volumes on the machine, not just this project) — this step requires
     typing the full word `yes`, not just `y`, given it affects every Docker
     project on the machine. Starting the OrbStack VM if it's stopped is
     itself flagged before doing it, since it has its own startup overhead.

### `report-only` (measured and displayed, never touched by the script)

- Draw Things model files (`~/Library/Containers/com.liuliu.draw-things/...
  /Models`) — Draw Things tracks its own model manifest (`custom.json`
  etc.); deleting `.ckpt` files directly from outside the app risks
  desyncing that manifest, so the script only reports size and recommends
  removing models via the app's own Model Zoo UI
- Movies / Downloads / Pictures under the user's home — personal files,
  never auto-handled
- Claude desktop app `vm_bundles` — informational only, no known safe
  cleanup
- Android SDK / emulator images (`~/Library/Android`) — out of scope for
  this iteration due to complexity/fragility of the Android SDK tooling;
  reported for visibility only

## Error Handling

Each target runs independently: if its underlying command
(`brew`/`docker`/`xcrun`/`pod`/`go`) is missing, or its target path doesn't
exist, the script prints a "skipped: <reason>" line for that target and
continues to the next one. The script does not use `set -e` globally, so one
target's failure never aborts the run; each target's action is wrapped so its
own failure is caught, reported, and treated as 0 bytes freed.

## Non-Goals

- No launchd/cron scheduling of the interactive cleanup (confirmed with
  user: manual-only for this iteration)
- No menu-bar app / resident process (may be revisited later if the script
  proves useful but insufficient)
- No automated handling of Draw Things models, Android SDK images, or any
  other report-only target
- No flags (`--dry-run`, `--yes-to-all`, etc.) — the interactive per-target
  prompt is the only mode

## Verification Plan

Since this script performs real destructive operations on the local
machine, verification is manual rather than automated:

1. Run the script and answer `N` to every prompt; confirm the reported sizes
   match the manual `du`/`df` investigation this design is based on
2. Answer `y` for one clearly safe `auto-safe` target (e.g. Xcode
   DerivedData), confirm the reported freed space matches the actual `df`
   change
3. For OrbStack/Docker, stop before the destructive `system prune -a
   --volumes` step in the first real run and only proceed after reviewing
   `docker system df` output
