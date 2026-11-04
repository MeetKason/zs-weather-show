#!/bin/sh
set -eu

if rg -n 'GoViewProAI|go-view-pro-ai' src/views/login/index.vue; then
  echo 'login page still references the product-announcement component' >&2
  exit 1
fi

echo 'login-ad-disabled: PASS'
