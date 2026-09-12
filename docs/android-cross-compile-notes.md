# Android (aarch64) 交叉编译踩坑记录

来自在 CI 上为 Android 编译 OpenSSH 的实践（2026-09），按遇到顺序排列。

## 1. 工具链与路径

- **NDK 解压目录名不确定** → 不要写死路径，动态探测：
  ```sh
  NDK_DIR=$(ls -d /opt/android-ndk-* | head -1)
  ```
- **NDK r23+ 已无 gcc 命名**，只有 `aarch64-linux-android<API>-clang`。若某构建脚本硬查
  `aarch64-linux-android-gcc`，需显式指定 `CC`。
- **OpenSSL 的 android target 依赖 `ANDROID_NDK_ROOT`** 环境变量来自动探测工具链；不设置会退回
  找老式 gcc，报 `no NDK aarch64-linux-android-gcc on $PATH`。
- **GitHub Actions 跨步骤变量**：`$GITHUB_ENV` 写入的变量**只对后续步骤生效**；同一步骤内请直接用绝对路径。

## 2. bionic 与 glibc 的差异

- **glibc 扩展在 bionic 不存在**（如 `__sentinel__`）→ `__attribute__((__sentinel__(1)))` 直接编译失败。
  解法：用 `-include` 头文件置空（**不要写 `-D__sentinel__(x)=`**，括号会被 shell 当作语法错误）：
  ```sh
  printf '#ifndef __sentinel__\n#define __sentinel__(x)\n#endif\n' > /tmp/bionic_compat.h
  export CFLAGS="-include /tmp/bionic_compat.h -Wno-error"
  ```
- **`getpwnam` 行为不同**：musl/glibc 静态二进制会去读 `/etc/passwd`（Android 没有该文件）→ 用户查找失败。
  **含用户查找的程序必须用 NDK（bionic）编译**。
- 交叉编译 OpenSSH 时另需 `--without-pam --with-sandbox=no`（Android 无 PAM / 无 Linux 安全模块）。

## 3. 安装路径（prefix）必须显式指定

产物要部署到特定目录时，`configure` 不指定就会默认装到 `/usr/local`：

```sh
./configure --host=aarch64-linux-android \
  --prefix=/data/adb/modules/<mod> \
  --sysconfdir=/data/adb/modules/<mod>/etc \
  --libexecdir=/data/adb/modules/<mod>/libexec \
  --with-privsep-path=/data/adb/modules/<mod>/empty
```

OpenSSH 9.x 是**多二进制架构**（`sshd` 运行时会调用 `libexec/sshd-session`、`sshd-auth` 等），
路径不对就起不来；搬产物时这些辅助二进制要一并带上。

## 4. 环境前提

- **Android 的 build-tools（aapt2/d8/zipalign）与官方 NDK prebuilt 只提供 x86_64** → aarch64 开发机无法完成
  Android 编译，需要 x86_64 机器或 CI；aarch64 上可用的是纯 Java 部分（`android.jar`、`apkanalyzer`、`cmdline-tools`）。
- repo 里若同时有 `bun.lock` / `pnpm-lock.yaml` / `uv.lock`，依赖漏洞扫描要覆盖全部锁文件（不同包管理器各扫一遍）。
