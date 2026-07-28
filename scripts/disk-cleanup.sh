#!/usr/bin/env bash
#
# Interactive disk-cleanup helper for this Mac.
# Run manually: ./scripts/disk-cleanup.sh
# No flags. Every destructive action requires an explicit per-target
# confirmation; report-only targets are never touched.
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/disk-cleanup-lib.sh
source "$SCRIPT_DIR/lib/disk-cleanup-lib.sh"

# Format: name|path|tier|check_cmd|clean_cmd|note|handler
# tier: auto-safe | confirm | report-only
# check_cmd: must succeed for the cleanup action to be offered; empty = always offered
# clean_cmd: shell command run on confirmation; empty when handler is set, or for report-only
# handler: empty = generic flow using clean_cmd; otherwise a dedicated function name suffix
TARGETS=(
  "Homebrew cache|$HOME/Library/Caches/Homebrew|auto-safe|command -v brew|brew cleanup|Deleted files are old formula/cask downloads; Homebrew re-downloads them on demand."
  "Xcode DerivedData|$HOME/Library/Developer/Xcode/DerivedData|auto-safe||rm -rf \"$HOME/Library/Developer/Xcode/DerivedData\"/*|Build cache only; Xcode regenerates it on the next build."
  "CoreSimulator unavailable devices|$HOME/Library/Developer/CoreSimulator/Devices|auto-safe|command -v xcrun|xcrun simctl delete unavailable|Removes simulator devices tied to no-longer-installed runtimes; always safe."
  "Go build cache|$HOME/Library/Caches/go-build|auto-safe|command -v go|go clean -cache|Go rebuilds this cache automatically on the next build."
  "pip cache|$HOME/Library/Caches/pip|auto-safe|command -v pip|pip cache purge|pip re-downloads packages into this cache on demand."
  "CocoaPods cache|$HOME/Library/Caches/CocoaPods|auto-safe|command -v pod|pod cache clean --all|CocoaPods re-downloads pods into this cache on demand."
  "node-gyp cache|$HOME/Library/Caches/node-gyp|auto-safe||rm -rf \"$HOME/Library/Caches/node-gyp\"/*|node-gyp re-downloads headers into this cache on demand."
  "Playwright browser cache|$HOME/Library/Caches/ms-playwright|confirm||rm -rf \"$HOME/Library/Caches/ms-playwright\"/*|Requires manually running 'npx playwright install' again afterward."
  "Playwright-go browser cache|$HOME/Library/Caches/ms-playwright-go|confirm||rm -rf \"$HOME/Library/Caches/ms-playwright-go\"/*|Requires manually reinstalling Playwright-go browsers afterward."
  "Google Chrome cache|$HOME/Library/Caches/Google|confirm||rm -rf \"$HOME/Library/Caches/Google\"/*|Close Chrome first; this clears its HTTP cache, not your profile/bookmarks."
  "iOS DeviceSupport|$HOME/Library/Developer/Xcode/iOS DeviceSupport|confirm|command -v xcrun||Keeps the 2 most recent iOS versions automatically; asks per older version.|ios_device_support"
  "OrbStack (Docker data)|$HOME/Library/Group Containers/HUAQ24HBR6.dev.orbstack/data|confirm|command -v docker||Two separate steps: build-cache-only prune, then full unused image/volume prune (requires typing 'yes').|orbstack_docker"
  "Draw Things models|$HOME/Library/Containers/com.liuliu.draw-things/Data/Documents/Models|report-only|||Delete via Draw Things' own Model Zoo UI, not this script — the app tracks a manifest that file-only deletion would desync."
  "Movies|$HOME/Movies|report-only|||Personal media; never auto-handled."
  "Downloads|$HOME/Downloads|report-only|||Personal files; never auto-handled."
  "Pictures|$HOME/Pictures|report-only|||Personal media; never auto-handled."
  "Claude vm_bundles|$HOME/Library/Application Support/Claude/vm_bundles|report-only|||Claude desktop app's sandbox VM bundle; no known safe cleanup."
  "Android SDK|$HOME/Library/Android|report-only|||Android SDK/emulator images; out of scope, shown for visibility only."
)

main() {
  local NAMES=() PATHS=() TIERS=() CHECK_CMDS=() CLEAN_CMDS=() NOTES=() HANDLERS=() SIZES_KB=()

  echo "Measuring known space-heavy locations..."
  echo ""

  local record name path tier check_cmd clean_cmd note handler size_kb
  for record in "${TARGETS[@]}"; do
    IFS='|' read -r name path tier check_cmd clean_cmd note handler <<< "$record"

    size_kb=0
    if [[ -e "$path" ]]; then
      size_kb=$(du -sk "$path" 2>/dev/null | awk '{print $1}')
      size_kb=${size_kb:-0}
    fi

    NAMES+=("$name")
    PATHS+=("$path")
    TIERS+=("$tier")
    CHECK_CMDS+=("$check_cmd")
    CLEAN_CMDS+=("$clean_cmd")
    NOTES+=("$note")
    HANDLERS+=("$handler")
    SIZES_KB+=("$size_kb")
  done

  local ORDER=()
  while IFS= read -r idx; do
    ORDER+=("$idx")
  done < <(
    for i in "${!SIZES_KB[@]}"; do
      printf '%012d %s\n' "${SIZES_KB[$i]}" "$i"
    done | sort -rn | awk '{print $2}'
  )

  printf '%-10s  %-14s  %s\n' "SIZE" "TIER" "NAME"
  local i size_bytes
  for i in "${ORDER[@]}"; do
    size_bytes=$(( SIZES_KB[i] * 1024 ))
    printf '%-10s  %-14s  %s\n' "$(bytes_to_human "$size_bytes")" "${TIERS[$i]}" "${NAMES[$i]}"
  done
}

main "$@"
