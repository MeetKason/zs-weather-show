#!/bin/sh
set -eu

source='src/views/project/index.vue'

if rg -n '不要在官方后端上发布|goDialog' "$source"; then
  echo 'project warning still exists' >&2
  exit 1
fi

echo 'project-warning-removed: PASS'
