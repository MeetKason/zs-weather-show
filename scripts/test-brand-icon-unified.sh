#!/bin/sh
set -eu

cmp -s src/assets/logo.png src/assets/images/login/input.png
file src/assets/logo.png | grep -q '512 x 512'
test -s public/favicon.ico

echo 'brand-icon-unified: PASS'
