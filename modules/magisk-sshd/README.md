# Magisk SSH 模块模板

把自带 OpenSSH 的 `sshd` 作为 root 服务在开机启动（端口 22，仅密钥认证）。

| 文件 | 作用 |
| --- | --- |
| `module.prop` | 模块元数据 |
| `service.sh` | 开机启动（等 `sys.boot_completed` 后拉起） |
| `action.sh` | Magisk 操作按钮：启停 + 状态 |
| `common.sh` | 共享逻辑（host key 生成 / PID / 日志 / 防重复启动） |
| `etc/sshd_config` | 配置（端口、密钥路径、sftp 子系统、端口转发） |
| `bin/` `libexec/` | **放置自编译的 OpenSSH 二进制**（见 `.github/workflows/build-openssh.yml`） |

## 使用步骤

1. 用 `.github/workflows/build-openssh.yml` 编译 aarch64 产物；
2. 把主程序（`sshd`、`ssh-keygen`）放进 `bin/`，辅助程序（`sshd-session`、`sshd-auth`、`sftp-server`）放进 `libexec/`；
3. 打包 zip（zip 根目录直接含 `module.prop` 等文件）；
4. 在 Magisk / KernelSU 里「从本地安装」→ 重启；
5. 把公钥追加到 `/data/adb/modules/sshd_autostart/etc/authorized_keys`。

## 安全提示

- 这是 **root 登录入口**，默认已收紧：`PermitRootLogin prohibit-password`、`PasswordAuthentication no`（仅密钥）；
- 建议只在可信网络使用；不用时在 Magisk 里禁用模块即可（不删数据）；
- `StrictModes no` 是为了适配 Android 上非标准 home 目录的既有实践，如需更严格可自行调整。
