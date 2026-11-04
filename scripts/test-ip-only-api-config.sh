#!/bin/sh
set -eu

if rg -n 'demo\.mtruning\.club|VITE_PRO_PATH[[:space:]]*=[[:space:]]*[^[:space:]#]*mtruning' .env src/api src/settings; then
  echo 'IP-only deployment still contains the old domain in API configuration' >&2
  exit 1
fi

echo 'ip-only-api-config: PASS'
