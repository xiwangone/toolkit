# Kotlin/Java 适配工作区

面向 Kotlin/Java 工程的分析工具与适配脚本，用于代码质量、架构与效率分析。

## 现状

- 已归档脚本：`arch_scan.py`（结构感知）、`dep_graph.py`（依赖图/循环依赖）、`quality_metrics.py`（MI/复杂度/健康分）、`risk_diagnose.py`（六类风险诊断）、`regression_guard.py`（回归基线对比）、`detect_code_ai.py` / `detect_text_ai.py`（AI 味检测）、`mcp_server.py`（MCP 封装，需 mcp+pydantic）
- 语言覆盖：Python / Go / C/C++ / Rust / TS / JS
- 待适配：Kotlin/Java 支持（见 `docs/ROADMAP.md` 阶段 2）

## 用法

```bash
python3 scripts/arch_scan.py --target <项目> --json
python3 scripts/quality_metrics.py --target <项目> --json
python3 scripts/risk_diagnose.py --target <项目> --json
python3 scripts/regression_guard.py record --output baseline.json
```

PowerShell 脚本（`vuln-scan.ps1` / `wf.ps1`）用于 Windows 环境。

## 许可

本目录组件遵循 MIT 许可证，原作者版权声明见 `LICENSE.arch-optimize`。