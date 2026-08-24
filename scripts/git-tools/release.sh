#!/usr/bin/env bash
# release.sh —— 触发 GitHub Actions 发版（release.yml，会 bump 版本、提交推 master、上传 APK 到 Release）
# 用法: release.sh <release_tag> [prerelease]
#   例: release.sh 2.46.2          （正式版）
#       release.sh 2.47.0-beta1 true（预发布）
# 前置: 已执行 vault_export_env（GITHUB_TOKEN；PAT 需含 workflow scope）
# 提示: 发版是重大对外操作，必须先经用户明确确认（含 tag 正确性）再执行
set -euo pipefail

TAG="${1:?用法: release.sh <release_tag> [prerelease]}"
PRE="${2:-false}"
ENV_FILE="${ENV_FILE:-/workspace/tmp/vault-env.sh}"
if [[ ! -f "$ENV_FILE" ]]; then
  echo "缺少 env 文件：请先让助手执行 vault_export_env（GITHUB_TOKEN）" >&2
  exit 2
fi
source "$ENV_FILE"
trap 'rm -f "$ENV_FILE"' EXIT

echo "将触发发版 tag=$TAG prerelease=$PRE"
CODE="$(curl -sS -o /dev/null -w '%{http_code}' -X POST \
  -H "Authorization: Bearer ${GITHUB_TOKEN}" \
  -H "Accept: application/vnd.github+json" \
  https://api.github.com/repos/xiwangone/rikkahub-agents/actions/workflows/release.yml/dispatches \
  -d "{\"ref\":\"master\",\"inputs\":{\"release_tag\":\"${TAG}\",\"prerelease\":\"${PRE}\"}}")"
if [[ "$CODE" == "204" ]]; then
  echo "✅ 已触发发版 $TAG，进度见 https://github.com/xiwangone/rikkahub-agents/actions"
else
  echo "❌ 触发失败 HTTP=$CODE（检查 token scope / workflow 文件名 / inputs 名）" >&2
  exit 1
fi