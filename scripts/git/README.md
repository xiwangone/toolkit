# 仓库操作脚本（通用版）

环境变量驱动，不绑定任何具体仓库或凭证系统。

| 变量 | 说明 |
| --- | --- |
| `REPO` | `owner/name`（如 `octocat/hello-world`） |
| `REF` | 分支，默认 `main` |
| `GH_TOKEN` | GitHub token（API 触发用，需 `workflow` scope） |
| `GH_SSH_KEY` | SSH 私钥内容（可选，推送用；不设则走默认 git 认证） |

## 脚本

| 脚本 | 用途 |
| --- | --- |
| `git-push.sh [remote] [branch]` | 推送：若有 `GH_SSH_KEY` 则写临时私钥推送并立即删除 |
| `ci-dispatch.sh <workflow-file> [json-inputs]` | 触发 workflow_dispatch（如 `ci-dispatch.sh build.yml`） |
| `cleanup-temp-creds.sh [--force]` | 检查（默认）/清理临时凭证文件 |

## 安全约定

- 凭证只经环境变量传入，脚本不落盘明文（SSH 私钥写临时文件后立即删除，`trap` 兜底）；
- 触发 CI / 发版属对外操作，执行前请人工确认；
- 用完检查临时残留：`cleanup-temp-creds.sh`
