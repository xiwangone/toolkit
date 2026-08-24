# git-tools —— 仓库工具链（跨环境通用版）

与 RikkaHub 沙箱工具链同源，可用在任意外部环境（Termux / Reasonix / 服务器）。**凭证按环境适配，本目录不含任何凭证**。

| 脚本 | 功能 |
| --- | --- |
| `push.sh` | 一键推送（SSH key 或 HTTPS token，推送后清理临时凭证） |
| `build.sh` | 触发 GitHub Actions 出包（build-apk.yml，只打包不发版） |
| `release.sh` | 触发发版（release.yml，需 tag，重大操作须用户确认） |
| `changelog.sh` | 生成两版本间变更日志草稿（中性措辞） |
| `cleanup.sh` | 清理临时凭证残留（默认只列，--force 删除） |
| `pack.sh` | 打包交付目录（沙箱路径版，其他环境自行改 SRC/OUT） |

## 凭证适配

- **RikkaHub 沙箱**：先 `vault_export_env`（凭证入 `/workspace/tmp/vault-env.sh`），再运行；脚本自动写临时 key → push → 立刻清理。
- **Termux / Reasonix**（推荐 https）：全局配置 `git config --global credential.helper '!f(){ echo username=<user>; echo password=$GITHUB_TOKEN; }; f'`，token 由用户自持于 shell 环境（如 `~/.bashrc` 的 `export GITHUB_TOKEN=...`）；或 SSH：配置 `~/.ssh/config` 走 443 直连 + `GIT_SSH_COMMAND` 引用私钥。
- 验证通道用 `git ls-remote origin`（不要用 `git credential fill`——会打印 token）。

## 合规提醒

- push / build / release 均属对外操作：先列影响面、经用户确认后执行；message 用中性词句；master 受保护禁 force push。