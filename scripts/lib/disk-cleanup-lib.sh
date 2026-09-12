#!/usr/bin/env bash

bytes_to_human() {
  local bytes="$1"
  awk -v b="$bytes" 'BEGIN {
    units[0]="B"; units[1]="K"; units[2]="M"; units[3]="G"; units[4]="T"
    u = 0
    v = b
    while (v >= 1024 && u < 4) {
      v = v / 1024
      u++
    }
    if (u == 0) {
      printf "%d%s", v, units[u]
    } else {
      printf "%.1f%s", v, units[u]
    }
  }'
}

# Reads version-like names on stdin and echoes the ones that are NOT among the
# newest "$1" entries, ordered oldest first. Sorting is version-aware, so
# "17.0" precedes "17.5" and "2025.3.4" precedes "2026.1.2".
candidates_excluding_newest() {
  local keep="$1"
  local names=()
  local line
  while IFS= read -r line; do
    [[ -n "$line" ]] && names+=("$line")
  done < <(sort -V)

  local total=${#names[@]}
  if (( total <= keep )); then
    return 0
  fi

  local cutoff=$(( total - keep ))
  local i
  for (( i = 0; i < cutoff; i++ )); do
    echo "${names[$i]}"
  done
}

ios_device_support_candidates() {
  candidates_excluding_newest 2
}

# Android Studio never prunes the per-release directories it leaves in
# ~/Library/{Application Support,Caches,Logs}/Google, so they accumulate one
# generation per upgrade. Three generations is enough to roll back to a
# previous release without keeping the whole history.
android_studio_candidates() {
  candidates_excluding_newest 3
}

parse_confirmation() {
  local input="$1"
  local default="$2"
  local normalized
  normalized="$(printf '%s' "$input" | tr '[:upper:]' '[:lower:]')"

  case "$normalized" in
    y|yes) echo "yes" ;;
    n|no) echo "no" ;;
    "")
      if [[ "$default" == "y" ]]; then
        echo "yes"
      else
        echo "no"
      fi
      ;;
    *) echo "no" ;;
  esac
}

parse_strict_yes() {
  local input="$1"
  local normalized
  normalized="$(printf '%s' "$input" | tr '[:upper:]' '[:lower:]')"
  if [[ "$normalized" == "yes" ]]; then
    echo "yes"
  else
    echo "no"
  fi
}
