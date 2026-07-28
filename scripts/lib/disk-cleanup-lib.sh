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
