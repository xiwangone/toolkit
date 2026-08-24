#!/usr/bin/env bash
# cleanup.sh —— 检查并清理临时凭证残留（默认只列出，加 --force 才真正删除）
# 用法: cleanup.sh [--force]
set -euo pipefail

TARGETS=(
  "/workspace/tmp/vault-env.sh"
  "/tmp/rikka_ssh_key.*"
  "/tmp/rikka_git_cred*"
  "/tmp/rikka_pub.txt"
)
FORCE="${1:-}"
FOUND=0

for pat in "${TARGETS[@]}"; do
  for f in $pat; do
    [[ -e "$f" ]] || continue
    FOUND=1
    if [[ "$FORCE" == "--force" ]]; then
      rm -f "$f" && echo "🗑  已删除: $f"
    else
      echo "⚠️  发现残留（加 --force 删除）: $f"
    fi
  done
done

if [[ -f ~/.ssh/config ]]; then
  perm=$(stat -c %a ~/.ssh/config 2>/dev/null)
  if [[ "$perm" != "600" ]]; then
    echo "⚠️  ~/.ssh/config 权限 $perm（应为 600，可 chmod 600）"
  fi
fi

[[ $FOUND -eq 0 ]] && echo "✅ 无临时凭证残留"