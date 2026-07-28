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

run_ios_device_support() {
  local path="$1"

  if [[ ! -d "$path" ]]; then
    echo "  Skipped: iOS DeviceSupport (path not found)"
    return
  fi

  local versions=() dirname
  while IFS= read -r dirname; do
    [[ -n "$dirname" ]] && versions+=("$dirname")
  done < <(find "$path" -mindepth 1 -maxdepth 1 -type d -exec basename {} \;)

  local candidates=""
  if (( ${#versions[@]} > 0 )); then
    candidates=$(printf '%s\n' "${versions[@]}" | ios_device_support_candidates)
  fi

  echo ""
  echo "  iOS DeviceSupport — keeping the 2 most recent versions automatically."

  if [[ -z "$candidates" ]]; then
    echo "  No old versions to remove (2 or fewer present)."
    return
  fi

  local candidates_list=() version
  while IFS= read -r version; do
    [[ -n "$version" ]] && candidates_list+=("$version")
  done <<< "$candidates"

  local i version_path before_kb before_bytes answer decision
  for (( i = 0; i < ${#candidates_list[@]}; i++ )); do
    version="${candidates_list[$i]}"
    version_path="$path/$version"
    before_kb=$(du -sk "$version_path" 2>/dev/null | awk '{print $1}')
    before_bytes=$(( before_kb * 1024 ))

    echo "  $version — $(bytes_to_human "$before_bytes")"
    read -r -p "  Delete this older version? [y/N] " answer
    decision=$(parse_confirmation "$answer" "n")

    if [[ "$decision" != "yes" ]]; then
      echo "  Skipped."
      continue
    fi

    rm -rf "$version_path"
    echo "  Freed $(bytes_to_human "$before_bytes")."
    TOTAL_FREED_BYTES=$(( TOTAL_FREED_BYTES + before_bytes ))
  done
}

run_orbstack_docker() {
  local path="$1"

  if ! command -v docker &>/dev/null; then
    echo "  Skipped: OrbStack (Docker data) (docker command not found)"
    return
  fi

  if ! docker info &>/dev/null; then
    local answer decision
    read -r -p "  OrbStack VM is stopped. Start it to inspect Docker data? Starting has its own overhead. [y/N] " answer
    decision=$(parse_confirmation "$answer" "n")
    if [[ "$decision" != "yes" ]]; then
      echo "  Skipped."
      return
    fi

    open -ga OrbStack
    local waited=0
    while ! docker info &>/dev/null && (( waited < 30 )); do
      sleep 2
      waited=$(( waited + 2 ))
    done

    if ! docker info &>/dev/null; then
      echo "  OrbStack did not become ready within 30s; skipping."
      return
    fi
  fi

  echo ""
  echo "  Docker disk usage:"
  docker system df

  local answer
  read -r -p "  Run 'docker builder prune' (build cache only)? [y/N] " answer
  if [[ "$(parse_confirmation "$answer" "n")" == "yes" ]]; then
    docker builder prune -f
  fi

  echo ""
  echo "  'docker system prune -a --volumes' removes ALL unused images,"
  echo "  containers, and volumes for EVERY Docker project on this Mac,"
  echo "  not just this one."
  read -r -p "  Type the full word 'yes' to run it, anything else to skip: " answer
  if [[ "$(parse_strict_yes "$answer")" == "yes" ]]; then
    docker system prune -a --volumes -f
  else
    echo "  Skipped."
  fi
}

run_generic_target() {
  local name="$1" path="$2" tier="$3" check_cmd="$4" clean_cmd="$5" note="$6"

  if [[ -n "$check_cmd" ]] && ! bash -c "$check_cmd" &>/dev/null; then
    echo "  Skipped: $name (requires: $check_cmd)"
    return
  fi

  if [[ ! -e "$path" ]]; then
    echo "  Skipped: $name (path not found)"
    return
  fi

  local before_kb before_bytes
  before_kb=$(du -sk "$path" 2>/dev/null | awk '{print $1}')
  before_bytes=$(( before_kb * 1024 ))

  local default="n"
  [[ "$tier" == "auto-safe" ]] && default="y"
  local prompt_hint="[y/N]"
  [[ "$default" == "y" ]] && prompt_hint="[Y/n]"

  echo ""
  echo "  $name — $(bytes_to_human "$before_bytes")"
  echo "  $note"
  local answer
  read -r -p "  Run cleanup? $prompt_hint " answer
  local decision
  decision=$(parse_confirmation "$answer" "$default")

  if [[ "$decision" != "yes" ]]; then
    echo "  Skipped."
    return
  fi

  bash -c "$clean_cmd"

  local after_kb after_bytes freed
  after_kb=$(du -sk "$path" 2>/dev/null | awk '{print $1}')
  after_kb=${after_kb:-0}
  after_bytes=$(( after_kb * 1024 ))
  freed=$(( before_bytes - after_bytes ))
  (( freed < 0 )) && freed=0

  echo "  Freed $(bytes_to_human "$freed")."
  TOTAL_FREED_BYTES=$(( TOTAL_FREED_BYTES + freed ))
}

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

  TOTAL_FREED_BYTES=0

  echo ""
  echo "Interactive cleanup (each item asks before doing anything):"

  for i in "${ORDER[@]}"; do
    [[ "${TIERS[$i]}" == "report-only" ]] && continue

    case "${HANDLERS[$i]}" in
      ios_device_support)
        run_ios_device_support "${PATHS[$i]}"
        ;;
      orbstack_docker)
        run_orbstack_docker "${PATHS[$i]}"
        ;;
      "")
        run_generic_target "${NAMES[$i]}" "${PATHS[$i]}" "${TIERS[$i]}" "${CHECK_CMDS[$i]}" "${CLEAN_CMDS[$i]}" "${NOTES[$i]}"
        ;;
    esac
  done
}

main "$@"
