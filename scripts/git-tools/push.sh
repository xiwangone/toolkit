#!/usr/bin/env bash
# push.sh —— GitHub/Gitee 一键推送（凭证经密钥库，AI 不见明文）
# 用法: push.sh [remote] [branch]
#   remote 默认 github-ssh（SSH 直连）；可选 origin（HTTPS token）或 gitee
#   branch 默认 master
# 前置: 本机已执行 vault_export_env 导出所需凭证（GITHUB_SSH_KEY 或 GITHUB_TOKEN）
# 效果: 自动写临时私钥 → push → 立即清理临时 key 与 env 文件
set -euo pipefail

REMOTE="${1:-github-ssh}"
BRANCH="${2:-master}"
ENV_FILE="${ENV_FILE:-/workspace/tmp/vault-env.sh}"

if [[ ! -f "$ENV_FILE" ]]; then
  echo "缺少 env 文件：请先让助手执行 vault_export_env（SSH 用 GITHUB_SSH_KEY；HTTPS 用 GITHUB_TOKEN）" >&2
  exit 2
fi

# shellcheck disable=SC1090
source "$ENV_FILE"

TMPKEY=""
SSHCMD=""
if [[ -n "${GITHUB_SSH_KEY:-}" ]]; then
  TMPKEY="$(mktemp /tmp/rikka_ssh_key.XXXXXX)"
  printf '%s\n' "${GITHUB_SSH_KEY}" > "$TMPKEY"
  chmod 600 "$TMPKEY"
  SSHCMD="ssh -i $TMPKEY -o IdentitiesOnly=yes"
fi

cleanup() { rm -f "$TMPKEY" "$ENV_FILE"; }
trap cleanup EXIT

if [[ -n "$SSHCMD" ]]; then
  git -c core.sshCommand="$SSHCMD" push "$REMOTE" "$BRANCH"
else
  git push "$REMOTE" "$BRANCH"
fi