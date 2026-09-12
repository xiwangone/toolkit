#!/usr/bin/env bash
# 三级本地检查：编译/构建 → 静态分析 → 依赖漏洞
# 用法: check.sh [项目根目录]
set -uo pipefail

ROOT="${1:-.}"
cd "$ROOT" || exit 2
FAIL=0
section() { echo; echo "════ $* ════"; }
have() { command -v "$1" >/dev/null 2>&1; }

section "1/3 编译/构建验证"
if [ -f package.json ] && [ -f pnpm-lock.yaml ]; then
  if [ ! -d node_modules ]; then
    echo "ℹ️ 未装依赖 → 跳过构建（先 pnpm install）"
  elif pnpm run build >/tmp/chk-build.log 2>&1; then
    echo "✅ pnpm build"
  else
    echo "❌ pnpm build"; tail -5 /tmp/chk-build.log; FAIL=1
  fi
fi
for d in */; do
  if [ -f "${d}pyproject.toml" ]; then
    python3 -m compileall -q "$d" >/dev/null 2>&1 && echo "✅ ${d} Python 语法" || echo "❌ ${d} Python 语法"
  fi
done
if [ -f app/build.gradle.kts ]; then
  echo "ℹ️ Kotlin/Android 编译需在具备 Android SDK 的机器执行（官方 build-tools 仅 x86_64）"
fi

section "2/3 静态分析"
if have ruff; then
  ruff check . >/tmp/chk-ruff.log 2>&1 && echo "✅ ruff" || echo "⚠️ ruff 告警（见 /tmp/chk-ruff.log）"
fi
if have oxlint && [ -d app ]; then
  oxlint app >/tmp/chk-oxlint.log 2>&1 && echo "✅ oxlint" || echo "⚠️ oxlint 告警（见 /tmp/chk-oxlint.log）"
fi
DETEKT_JAR="${DETEKT_JAR:-$HOME/.cache/detekt-cli.jar}"
if [ -f "$DETEKT_JAR" ] && [ -f app/build.gradle.kts ]; then
  CFG="${DETEKT_CFG:-$(dirname "$0")/detekt.yml}"
  BASE="${DETEKT_BASELINE:-$ROOT/detekt-baseline.xml}"
  ARGS="--input app/src/main/java --build-upon-default-config --config $CFG"
  [ -f "$BASE" ] && ARGS="$ARGS --baseline $BASE"
  if java -Xmx2g -jar "$DETEKT_JAR" $ARGS >/tmp/chk-detekt.log 2>&1; then
    echo "✅ detekt"
  else
    echo "⚠️ detekt 有新增问题（见 /tmp/chk-detekt.log；既有问题用基线登记：--create-baseline）"
  fi
else
  echo "ℹ️ 未配置 detekt（下载 detekt-cli-*-all.jar 后设 DETEKT_JAR）"
fi

section "3/3 依赖漏洞扫描"
OSV="${OSV_SCANNER:-$(command -v osv-scanner || true)}"
if [ -n "$OSV" ] && [ -x "$OSV" ]; then
  "$OSV" scan -r . 2>&1 | tail -20
else
  echo "ℹ️ 未安装 osv-scanner（https://github.com/google/osv-scanner/releases）"
fi

echo
if [ $FAIL -eq 0 ]; then echo "════ ✅ 无阻断项 ════"; else echo "════ ❌ 存在阻断项 ════"; fi
exit $FAIL
