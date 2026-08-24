# 工具集

面向本地工程场景的工具与适配脚本集合：代码分析、质量检查、工程效率。持续扩展，新增工具按主题放入独立子目录。

## 目录

| 路径 | 说明 |
| --- | --- |
| `adapters/kotlin-java/` | Kotlin/Java 工程分析工具的适配工作区（含 arch-optimize 组件，MIT，版权见子目录 LICENSE 文件） |
| `skills/` | 引用的标准 Agent 技能（mcp-builder / frontend-design / kotlin-tooling-agp9-migration / kotlin-tooling-java-to-kotlin，Apache-2.0，许可随技能目录保留） |
| `scripts/` | 通用效率脚本（`audit.sh` 一键架构体检；`git-tools/` 跨环境仓库工具链） |
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
bash scripts/audit.sh <项目>          # 一键体检：四份 JSON + Markdown 报告
```

## Synaptic（代码图谱）

- 二进制由 CI 编译（`.github/workflows/build-synaptic.yml`，x86_64 + aarch64），从 Actions artifact 获取（`synaptic-linux-binaries`，保留 30 天）。
- 常用命令：`synaptic extract <项目>`（建图，输出 synaptic-out/ 多格式图谱：graph.html/json/svg/dot/graphml/cypher）、`synaptic refs <符号>` / `query` / `path`（图谱查询）、`synaptic serve`（MCP server，供 AI 助手用）。
- 实测（aarch64 设备，Kotlin 仓库）：183 代码文件 → 3298 节点 / 8088 边 / 23 社区；`GRAPH_REPORT.md` 输出 God Nodes 与架构统计。
- **许可：AGPL-3.0-or-later**——本地/CI 内部使用 OK；对外分发/再发布前须履行 AGPL 义务。

## 许可证

MIT。各组件遵循各自开源许可证，原作者版权声明保留于对应 LICENSE 文件（如 `adapters/kotlin-java/LICENSE.arch-optimize`）。