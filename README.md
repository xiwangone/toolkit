# 工具集

面向本地工程场景的工具与适配脚本集合：代码分析、质量检查、工程效率。持续扩展，新增工具按主题放入独立子目录。

## 目录

| 路径 | 说明 |
| --- | --- |
| `adapters/kotlin-java/` | Kotlin/Java 工程分析工具的适配工作区（含 arch-optimize 组件，MIT，版权见子目录 LICENSE 文件） |
| `skills/` | 引用的标准 Agent 技能（mcp-builder / frontend-design / kotlin-tooling-agp9-migration，Apache-2.0，许可随技能目录保留） |
| `scripts/` | 通用效率脚本（如 `audit.sh` 一键架构体检） |
| `docs/` | 说明与规划（`ROADMAP.md`）与参考索引（`REFERENCE.md`） |
| `.github/workflows/` | CI：构建类任务（如 Synaptic 编译）在 GitHub Actions 上运行，产物上传 artifact |

## 使用

各子目录自带说明；Python 脚本要求 Python 3.8+（纯标准库，无第三方依赖），PowerShell 脚本要求 Windows PowerShell。示例：

```bash
python3 adapters/kotlin-java/scripts/arch_scan.py --target <项目> --json
python3 adapters/kotlin-java/scripts/dep_graph.py --target <项目> --json
python3 adapters/kotlin-java/scripts/quality_metrics.py --target <项目> --json
python3 adapters/kotlin-java/scripts/risk_diagnose.py --target <项目> --json
python3 adapters/kotlin-java/scripts/regression_guard.py record --output <基线.json>
```

## 许可证

MIT。各组件遵循各自开源许可证，原作者版权声明保留于对应 LICENSE 文件（如 `adapters/kotlin-java/LICENSE.arch-optimize`）。