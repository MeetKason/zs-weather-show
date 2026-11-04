#!/bin/sh
set -eu

patterns='mtruning\.club|goviewlink\.com|gitee\.com/(MTrun|dromara)/go-view|docs\.apipost\.cn|beian\.miit\.gov\.cn'
scan_paths='src public index.html README.md deploy'

if rg -n --hidden --glob '!node_modules' --glob '!.git' "$patterns" $scan_paths; then
  echo 'open-source or upstream deployment references remain' >&2
  exit 1
fi

echo 'private-deployment-references: PASS'
