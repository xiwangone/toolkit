#!/usr/bin/env bash
# 通用推送：可选 SSH 私钥（环境变量传入，不落盘明文）
# 用法: REPO_REMOTE=origin REF=main git-push.sh [remote] [branch]
set -euo pipefail

REMOTE="${1:-${REPO_REMOTE:-origin}}"
BRANCH="${2:-${REF:-main}}"
TMPKEY=""

cleanup() { [[ -n "$TMPKEY" ]] && rm -f "$TMPKEY"; }
trap cleanup EXIT

if [[ -n "${GH_SSH_KEY:-}" ]]; then
  TMPKEY="$(mktemp /tmp/git-ssh-key.XXXXXX)"
  printf '%s\n' "$GH_SSH_KEY" > "$TMPKEY"
  chmod 600 "$TMPKEY"
  git -c core.sshCommand="ssh -i $TMPKEY -o IdentitiesOnly=yes -o StrictHostKeyChecking=accept-new" push "$REMOTE" "$BRANCH"
else
  git push "$REMOTE" "$BRANCH"
fi
echo "✅ pushed: $REMOTE/$BRANCH"
