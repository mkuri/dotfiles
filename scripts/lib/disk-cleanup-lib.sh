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

ios_device_support_candidates() {
  local keep=2
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
