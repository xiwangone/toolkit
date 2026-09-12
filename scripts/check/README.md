# 本地检查（三级）

```bash
scripts/check/check.sh [项目根目录]
```

| 级别 | 内容 | 说明 |
| --- | --- | --- |
| 1 | 编译/构建 | 前端 `pnpm build`、Python 语法；**Kotlin/Android 编译需在有 SDK 的机器上做**（build-tools 官方仅 x86_64） |
| 2 | 静态分析 | `ruff`（Python）、`oxlint`（前端）、`detekt`（Kotlin） |
| 3 | 依赖漏洞 | `osv-scanner` 递归扫描所有锁文件（npm/pnpm/yarn/bun/pip/uv/gradle 等） |

## 依赖的工具（按需安装）

| 工具 | 安装 |
| --- | --- |
| osv-scanner | 从 [releases](https://github.com/google/osv-scanner/releases) 下载对应架构二进制 |
| detekt | 下载 `detekt-cli-*-all.jar`，设 `DETEKT_JAR` 指向它 |
| ruff | `pip install ruff` |
| oxlint | 随前端依赖（`pnpm exec oxlint`） |

## detekt 基线

首次在存量项目上运行会有大量既有告警 → 先登记基线，之后只报**新增**：

```bash
java -jar detekt-cli-all.jar --input app/src/main/java \
  --build-upon-default-config --config scripts/check/detekt.yml \
  --baseline detekt-baseline.xml --create-baseline
```

`detekt.yml` 已关掉风格类规则（`naming`/`style`），只留 `potential-bugs`/`performance`/`exceptions`/`coroutines`/`complexity`。
