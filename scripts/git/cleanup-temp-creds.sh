#!/usr/bin/env bash
# 检查并清理临时凭证文件（默认只列出）
# 用法: cleanup-temp-creds.sh [--force]
set -euo pipefail

TARGETS=(
  "/tmp/git-ssh-key.*"
  "/tmp/*vault-env*"
  "/tmp/*cred*"
)
FORCE="${1:-}"
FOUND=0

for pat in "${TARGETS[@]}"; do
  for f in $pat; do
    [[ -e "$f" ]] || continue
    FOUND=1
    if [[ "$FORCE" == "--force" ]]; then
      rm -f "$f" && echo "已删除: $f"
    else
      echo "发现残留（加 --force 删除）: $f"
    fi
  done
done

if [[ -f ~/.ssh/config ]]; then
  perm=$(stat -c %a ~/.ssh/config 2>/dev/null || echo "?")
  [[ "$perm" != "600" ]] && echo "~/.ssh/config 权限 $perm（建议 600）"
fi

[[ $FOUND -eq 0 ]] && echo "✅ 无临时凭证残留"
