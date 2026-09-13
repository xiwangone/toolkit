# Magisk SSH 模块模板

把**自带 OpenSSH** 的 `sshd` 作为 root 服务在开机启动（端口 22，仅密钥认证）。

## 设计边界（重要）

- 模块**自带 OpenSSH 二进制**并独立开机自启 —— 目的就是**不依赖 Termux / 其它外部 sshd**。
- 模块**不预置任何 `authorized_keys` 或私钥**：公钥由使用者在安装后自行添加（私钥永远不应进模块包/仓库）。
- host key 由 `common.sh` 在首次启动时用自带的 `ssh-keygen` 生成（模块目录内），无需外部工具。

| 文件 | 作用 |
| --- | --- |
| `module.prop` | 模块元数据 |
| `service.sh` | 开机启动（等 `sys.boot_completed` 后拉起） |
| `action.sh` | Magisk 操作按钮：启停 + 状态 |
| `common.sh` | 共享逻辑（host key 生成 / PID / 日志 / 防重复启动） |
| `etc/sshd_config` | 配置（端口、密钥路径、sftp 子系统、KEX/公钥算法、端口转发） |
| `bin/` `libexec/` | **放置自编译的 OpenSSH 二进制**（见下） |

## 使用步骤

1. 编译 aarch64 产物：本地/CI 共用脚本 `scripts/build/build-openssh-android.sh <NDK> <WORK> <OUT> 26`（CI 入口 `.github/workflows/build-openssh.yml`）；
2. 把主程序（`sshd`、`ssh-keygen`、`scp`）放进 `bin/`，辅助程序（`sshd-session`、`sftp-server`、`sshd-auth`）放进 `libexec/`；
3. 打包 zip（zip 根目录直接含 `module.prop` 等文件）；
4. 在 Magisk / KernelSU 里「从本地安装」→ 重启；
5. 把**自己的公钥**追加到 `/data/adb/modules/sshd_autostart/etc/authorized_keys`（模块不含公钥）。

## 已知适配（Android / bionic，构建侧已处理）

| 项 | 说明 |
| --- | --- |
| `getpwuid`/`getpwnam` | Android 无 passwd 数据库，bionic 返回 NULL 或字段残缺 → sshd/ssh-keygen 直接解引用会 **SEGV**；构建脚本已把调用点重定向到合成条目 |
| `explicit_bzero` / `_PATH_MAILDIR` / `bzero` / `utmp*` / `futimes` | 逐项在兼容头或 configure 探测中处理 |
| `getrrsetbyname` / curve25519 ref 的 `select` | 前者给降级实现，后者改名 |

### sshd_config 里的两条兼容项（勿删）

```
KexAlgorithms ecdh-sha2-nistp256,ecdh-sha2-nistp384,ecdh-sha2-nistp521,diffie-hellman-group-exchange-sha256,diffie-hellman-group16-sha512,diffie-hellman-group18-sha512,diffie-hellman-group14-sha256
PubkeyAcceptedAlgorithms +ssh-rsa
HostkeyAlgorithms +ssh-rsa
```

- 第一条：`sntrup761x25519-sha512@openssh.com` / `curve25519-sha256` 在本机构建下 KEX 阶段会失败（preauth 子进程退出，表现为连接被关闭）；
- 后两条：兼容仅支持 `ssh-rsa`(SHA-1) 签名的旧客户端（如 JSch）。

## 安全提示

- 这是 **root 登录入口**，默认已收紧：`PermitRootLogin prohibit-password`、`PasswordAuthentication no`（仅密钥）；
- 建议只在可信网络使用；不用时在 Magisk 里禁用模块即可（不删数据）；
- `StrictModes no` 是为了适配 Android 上非标准 home 目录的既有实践，如需更严格可自行调整；
- 目前保存的 SSH 用户名需为 `root`（合成 passwd 只提供 root 条目）。
