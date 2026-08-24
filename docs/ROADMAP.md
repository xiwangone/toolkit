# 工具集路线图

滚动扩展规划；完成一项更新一项。

## 阶段 1（当前）：资产归档
- 归档 arch-optimize 组件（SKILL.md + 8 个 Python 脚本 + 2 个 PowerShell 脚本 + references）→ `adapters/kotlin-java/`，保留 MIT 许可与版权声明

## 阶段 2：Kotlin/Java 语言适配 ✅ 已完成
- `dep_graph.py`：注册 .java/.kt，新增 Java/Kotlin import 解析（`import a.b.C;` / `import a.b as c`），纳入模块依赖图与循环依赖检测
- `quality_metrics.py`：补 Kotlin `fun` 函数提取与决策点正则（FUNC_RE / DECISION_RE），实测可提取 Kotlin 函数并计算复杂度
- `risk_diagnose.py`：同步注册 .kt/.java，补 import 提取分支，R1-R6 全量扫描 Kotlin 源码
- 验证：对 reasonix-agents（Kotlin）与 rikkahub-agents（多模块）实测通过

## 阶段 3：Synaptic（CodeGraph）集成
- 编译类任务在 CI 执行（`.github/workflows/build-synaptic.yml`，手动触发，产物上传 artifact），不占本地资源
- 产物纳入本仓库 `bin/`，本地直接索引 Kotlin/Java 仓库出代码图谱

## 阶段 4：代码质量门禁 / 开发修复类扩展（进行中）
- ✅ 一键体检脚本 `scripts/audit.sh`（结构/依赖/质量/风险，输出 JSON + Markdown 报告）
- ✅ 引用技能：`skills/mcp-builder`（MCP 服务开发）、`skills/frontend-design`（前端/UI 交互设计）、`skills/kotlin-tooling-agp9-migration` 与 `skills/kotlin-tooling-java-to-kotlin`（Kotlin 官方 Gradle/迁移）；均 Apache-2.0，许可保留
- ✅ 仓库工具链跨环境版 `scripts/git-tools/`（push/build/release/changelog/cleanup/pack，凭证按环境适配：沙箱 vault / Termux $GITHUB_TOKEN 或 SSH key）
- ✅ 跨 Agent 兼容：技能遵循 Agent Skills 标准（SKILL.md + frontmatter），Reasonix / Claude Code / Codex / RikkaHub 均可直接使用
- ✅ 参考索引 `docs/REFERENCE.md`（高价值开源项目：anthropics/skills、awesome-agent-skills、static-analysis、awesome-cli-apps、Kotlin 官方技能、Synaptic 等）
- 待办：质量门禁脚本（健康分、零退化率检查）接入常用工程流程；开发修复类工具（代码审查、变更影响评估）逐步补充