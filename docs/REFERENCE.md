# 参考索引

高价值开源参考项目索引，供工具集扩展与选型参考。引用第三方代码/技能时保留原作者版权声明与许可证。

| 项目 | 说明 | 许可 |
| --- | --- | --- |
| anthropics/skills（171k⭐） | Agent Skills 官方技能示例 + 规范 + 模板 | 多数 Apache-2.0；docx/pdf/pptx/xlsx 为 source-available（非开源） |
| VoltAgent/awesome-agent-skills（31.7k⭐） | 1497+ 精选 Agent 技能索引（官方团队 + 社区） | 各技能随源仓库 |
| analysis-tools-dev/static-analysis | 全语言静态分析（SAST）与 linter 工具目录 | 索引，各工具随各自许可 |
| agarrharr/awesome-cli-apps（~20k⭐） | CLI 工具清单（按用途分类） | 索引 |
| Kotlin/kotlin-agent-skills（1k⭐） | Kotlin 官方 AI 技能（backend/tooling 类） | Apache-2.0 |
| agentskills.io | Agent Skills 规范标准 | 规范文档 |
| reasonix.io/skills/ | Reasonix 生态技能市场（skill/mcp/plugin 三类，带安装量） | 随各包 |
| ColinVaughn/Synaptic（CodeGraph） | 跨语言代码图谱（34+ 语言含 Kotlin/Java），MCP 可选 | MIT |
| dev-vikas-soni/gradle-lighthouse | Android Gradle 模块图、循环依赖、构建审计（需 Gradle/JVM） | 随仓库 |

## 使用建议

- 新技能优先从 anthropics/skills 与 Kotlin/kotlin-agent-skills 找标准 SKILL.md 技能，拷贝时连同 LICENSE 一起保留。
- 需要代码图谱/语义索引时用 Synaptic（本仓库 CI 已配置编译，见 `.github/workflows/build-synaptic.yml`）。
- 需要 Android 模块级依赖图时用 gradle-lighthouse（有构建环境后启用）。
- 工具选择以许可证兼容（MIT/Apache-2.0/BSD）与本地/CI 可落地为优先。