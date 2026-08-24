#!/usr/bin/env bash
# pack.sh —— 打包交付目录为 zip（部署用）
# 用法: pack.sh [输出路径]  （默认 /workspace/交付-YYYYMMDD.zip）
set -euo pipefail

SRC="/workspace/交付"
OUT="${1:-/workspace/交付-$(date +%Y%m%d).zip}"
[[ -d "$SRC" ]] || { echo "未找到 $SRC" >&2; exit 1; }

cd /workspace
rm -f "$OUT"
# 排除 工具/ 下的 zip，避免打包产物自包含越打越大
zip -rq "$OUT" 交付 -x '交付/工作区/工具/*.zip'
echo "✅ 已打包: $OUT"
unzip -l "$OUT" | tail -3