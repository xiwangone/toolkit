#!/usr/bin/env bash
# audit.sh —— 一键架构体检（结构/依赖/质量/风险），输出 JSON + Markdown 摘要
# 用法: audit.sh <项目目录> [输出目录]
# 依赖: 本仓库 adapters/kotlin-java/scripts 下的分析脚本
set -euo pipefail
BASE="$(cd "$(dirname "$0")/.." && pwd)"
S="$BASE/adapters/kotlin-java/scripts"
TARGET="${1:?用法: audit.sh <项目目录> [输出目录]}"
OUT="${2:-${TARGET%/}/../audit-$(date +%Y%m%d-%H%M%S)}"
mkdir -p "$OUT"
python3 "$S/arch_scan.py" --target "$TARGET" --json  > "$OUT/arch.json"
python3 "$S/dep_graph.py" --target "$TARGET" --json  > "$OUT/dep.json"
python3 "$S/quality_metrics.py" --target "$TARGET" --json > "$OUT/quality.json"
python3 "$S/risk_diagnose.py" --target "$TARGET" --json > "$OUT/risk.json"
python3 - "$TARGET" "$OUT" <<'PY'
import json, sys
target, out = sys.argv[1], sys.argv[2]
d=json.load(open(f"{out}/dep.json")); q=json.load(open(f"{out}/quality.json")); r=json.load(open(f"{out}/risk.json"))
lines=[f"# 架构体检报告 — {target}", ""]
lines.append(f"- 模块数: {len(d.get('modules',[]))} | 跨模块依赖边: {len(d.get('edges',[]))} | 循环依赖: {len(d.get('circular_deps',[]))}")
lines.append(f"- 质量: 文件 {q.get('files_analyzed')} | LOC {q.get('total_loc')} | MI {q.get('average_mi')} | CC {q.get('average_cc')} | 健康分 {q.get('health_score')}")
rb=r.get("findings_by_risk",{})
lines.append(f"- 风险发现: 总数 {r.get('total_findings')} | " + " | ".join(f"{k}={len(rb.get(k,[]))}" for k in ["R1","R2","R3","R4","R5","R6"]))
lines.append("")
lines.append("## 热点文件 TOP")
for h in q.get("hotspots",[])[:15]:
    lines.append(f"- {h.get('function','?')}():{h.get('line','?')} | CC={h.get('cc')} | {h.get('issue','?')}")
open(f"{out}/audit-report.md","w",encoding="utf-8").write("\n".join(lines))
print(f"报告: {out}/audit-report.md")
PY
