#!/bin/sh
set -eu

source='src/views/chart/ContentHeader/headerRightBtn/index.vue'

rg -n 'const copyPreviewPath = async' "$source" >/dev/null
rg -n 'await copy\(\)' "$source" >/dev/null
rg -n "document\.execCommand\('copy'\)" "$source" >/dev/null
rg -n 'copyPreviewPathFallback|createElement\('\''textarea'\''\)' "$source" >/dev/null

echo 'copy-preview-path: PASS'
