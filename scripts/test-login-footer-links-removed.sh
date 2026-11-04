#!/bin/sh
set -eu

if rg -n 'layout-footer|LayoutFooter|docPath|beian\.miit\.gov\.cn' src/views/login/index.vue; then
  echo 'login page still references the external-link footer' >&2
  exit 1
fi

echo 'login-footer-links-removed: PASS'
