#!/bin/sh
set -eu

if ! rg -n 'location[[:space:]]*=[[:space:]]*/index\.html' deploy/nginx.conf >/dev/null || \
   ! rg -n 'Cache-Control.*no-store' deploy/nginx.conf >/dev/null; then
  echo 'index.html is not configured to avoid stale frontend bundles' >&2
  exit 1
fi

echo 'index-cache-policy: PASS'
