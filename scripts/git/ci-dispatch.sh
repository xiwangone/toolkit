#!/usr/bin/env bash
# 触发 GitHub Actions workflow_dispatch（支持自定义 inputs）
# 用法: REPO=owner/name GH_TOKEN=xxx ci-dispatch.sh <workflow-file> [ref] [json-inputs]
#   例: ci-dispatch.sh build.yml main
#       ci-dispatch.sh release.yml main '{"tag":"1.2.3"}'
set -euo pipefail

WF="${1:?用法: ci-dispatch.sh <workflow-file> [ref] [json-inputs]}"
REF="${2:-${REF:-main}}"
INPUTS="${3:-}"
: "${REPO:?需要环境变量 REPO=owner/name}"
: "${GH_TOKEN:?需要环境变量 GH_TOKEN}"

BODY="{\"ref\":\"${REF}\"}"
[[ -n "$INPUTS" ]] && BODY="{\"ref\":\"${REF}\",\"inputs\":${INPUTS}}"

CODE="$(curl -sS -o /dev/null -w '%{http_code}' -X POST \
  -H "Authorization: Bearer ${GH_TOKEN}" \
  -H "Accept: application/vnd.github+json" \
  "https://api.github.com/repos/${REPO}/actions/workflows/${WF}/dispatches" \
  -d "$BODY")" || true

if [[ "$CODE" == "204" ]]; then
  echo "✅ 已触发 ${WF}（ref=${REF}）：https://github.com/${REPO}/actions"
else
  echo "❌ 触发失败 HTTP=$CODE（检查 token 的 workflow scope / workflow 文件名 / inputs 名）" >&2
  exit 1
fi
