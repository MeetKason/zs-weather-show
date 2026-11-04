#!/bin/sh
set -eu

rg -n "username: 'admin'" src/views/login/index.vue >/dev/null
rg -n "password: ''" src/views/login/index.vue >/dev/null
echo 'login-default-credentials: PASS'
