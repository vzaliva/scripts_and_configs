#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 <duration>"
  echo "Examples: 3h | 10m | 5s | 3h15m | 28h1m1s"
  exit 1
fi

input="$1"
total=0

# Parse duration like 3h15m10s
while [[ $input =~ ^([0-9]+)([hms])(.*)$ ]]; do
  value="${BASH_REMATCH[1]}"
  unit="${BASH_REMATCH[2]}"
  input="${BASH_REMATCH[3]}"

  case "$unit" in
    h) (( total += value * 3600 )) ;;
    m) (( total += value * 60 )) ;;
    s) (( total += value )) ;;
  esac
done

if [[ -n "$input" || $total -le 0 ]]; then
  echo "Invalid duration format"
  exit 1
fi

while (( total > 0 )); do
  h=$(( total / 3600 ))
  m=$(( (total % 3600) / 60 ))
  s=$(( total % 60 ))
  printf "\rRemaining: %02d:%02d:%02d " "$h" "$m" "$s"
  sleep 1
  (( total-- ))
done

printf "\rRemaining: 00:00:00\n"
