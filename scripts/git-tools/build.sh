#!/usr/bin/env bash
# build.sh —— 触发 GitHub Actions 出包（build-apk.yml，只打包、不发版）
# 用法: build.sh
# 前置: 已执行 vault_export_env（GITHUB_TOKEN；PAT 需含 workflow scope）
# 提示: 触发 CI 属对外操作，需用户在场确认后执行
set -euo pipefail

ENV_FILE="${ENV_FILE:-/workspace/tmp/vault-env.sh}"
if [[ ! -f "$ENV_FILE" ]]; then
  echo "缺少 env 文件：请先让助手执行 vault_export_env（GITHUB_TOKEN）" >&2
  exit 2
fi
source "$ENV_FILE"
trap 'rm -f "$ENV_FILE"' EXIT

CODE="$(curl -sS -o /dev/null -w '%{http_code}' -X POST \
  -H "Authorization: Bearer ${GITHUB_TOKEN}" \
  -H "Accept: application/vnd.github+json" \
  https://api.github.com/repos/xiwangone/rikkahub-agents/actions/workflows/build-apk.yml/dispatches \
  -d '{"ref":"master"}')"
if [[ "$CODE" == "204" ]]; then
  echo "✅ 已触发出包（build-apk.yml），进度见 https://github.com/xiwangone/rikkahub-agents/actions"
else
  echo "❌ 触发失败 HTTP=$CODE（检查 token 的 workflow scope，或确认 workflow 文件名）" >&2
  exit 1
fi