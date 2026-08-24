#!/usr/bin/env bash
# changelog.sh —— 生成两个版本间的 changelog 草稿（中性措辞，需人工整理）
# 用法: changelog.sh <from> [to]   在 git 仓库目录内运行
#   例: changelog.sh 2.46.1           # 2.46.1..HEAD
#        changelog.sh 2.46.0 2.46.1   # 2.46.0..2.46.1
set -euo pipefail

FROM="${1:?用法: changelog.sh <from> [to]}"
TO="${2:-HEAD}"
ROOT="$(git rev-parse --show-toplevel 2>/dev/null)" || { echo "请在 git 仓库目录内运行" >&2; exit 1; }

git -C "$ROOT" log --pretty=format:'%s' "$FROM".."$TO" 2>/dev/null | grep -v -E '^\s*$' > /tmp/changelog_raw.txt

echo "=== 变更日志草稿（$FROM..$TO，共 $(wc -l < /tmp/changelog_raw.txt) 条）==="
echo "（整理要求：中性词句 新增/修复/优化/调整；删除内部讨论与无关内容；不发未验证项）"
echo "----------------------------------------------------------------"
cat /tmp/changelog_raw.txt
echo "----------------------------------------------------------------"
echo "草稿已存 /tmp/changelog_raw.txt"