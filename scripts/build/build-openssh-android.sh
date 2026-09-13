#!/usr/bin/env bash
# 交叉编译 OpenSSH（aarch64 / Android，NDK clang）
# 本地（WSL/Linux）与 CI 通用：同一份脚本，避免两边参数漂移。
#
# 用法: build-openssh-android.sh <NDK_ROOT> <WORK_DIR> <OUT_DIR> [API_LEVEL]
#   <NDK_ROOT>  NDK 根目录（需含 toolchains/llvm/prebuilt/linux-x86_64）
#   <WORK_DIR>  下载/编译工作目录（建议放本地盘，勿用 /mnt 之类慢挂载）
#   <OUT_DIR>   产物输出目录（生成 bin/ 与 libexec/）
#   [API_LEVEL] 目标 API（默认 26）
#
# 产物布局（与 Magisk 模块约定一致）：
#   OUT/bin/       sshd ssh-keygen scp
#   OUT/libexec/   sshd-session sftp-server (sshd-auth)
set -euo pipefail

NDK="${1:?need NDK root}"
WORK="${2:?need work dir}"
OUT="${3:?need out dir}"
API="${4:-26}"
HOST=aarch64-linux-android
CC="${HOST}${API}-clang"
OPENSSL_VER=3.0.15
SSH_VER=9.9p2

export ANDROID_NDK_ROOT="$NDK"
export PATH="$NDK/toolchains/llvm/prebuilt/linux-x86_64/bin:$PATH"
mkdir -p "$WORK" "$OUT"
cd "$WORK"

command -v "$CC" >/dev/null || { echo "找不到 $CC（NDK 路径或 prebuilt 架构不符？）" >&2; exit 1; }

echo "== 0 工具链 =="
"$CC" --version | head -2

# ---------- 源码 ----------
echo "== 1 依赖源码 =="
[ -d "openssl-$OPENSSL_VER" ] || {
  curl -sL --retry 3 -o ssl.tgz "https://github.com/openssl/openssl/releases/download/openssl-$OPENSSL_VER/openssl-$OPENSSL_VER.tar.gz"
  tar xzf ssl.tgz
}
[ -d "openssh-$SSH_VER" ] || {
  curl -sL --retry 3 -o ssh.tgz "https://cdn.openbsd.org/pub/OpenBSD/OpenSSH/portable/openssh-$SSH_VER.tar.gz"
  tar xzf ssh.tgz
}

# ---------- OpenSSL（静态，只需一次） ----------
SSL_PREFIX="$WORK/ssl"
if [ ! -f "$SSL_PREFIX/lib/libcrypto.a" ]; then
  echo "== 2 编译 OpenSSL =="
  cd "$WORK/openssl-$OPENSSL_VER"
  ./Configure android-arm64 -D__ANDROID_API__="$API" no-shared no-tests --prefix="$SSL_PREFIX"
  make -j"$(nproc)"
  make install_sw
fi
ls -l "$SSL_PREFIX/lib/libcrypto.a"

# ---------- bionic 兼容头（-include 注入到每个编译单元） ----------
# __sentinel__: glibc 扩展，bionic 无
# explicit_bzero: bionic 到 API 30 才声明；这里提供等价实现
# _PATH_MAILDIR: Android 无 /var/mail 路径
COMPAT="$WORK/bionic_compat.h"
cat > "$COMPAT" <<'EOF'
#ifndef __sentinel__
#define __sentinel__(x)
#endif
#include <string.h>
#include <strings.h>
#ifndef _PATH_MAILDIR
#define _PATH_MAILDIR "/data/local/tmp"
#endif
static inline void explicit_bzero(void *p, size_t n) {
    memset(p, 0, n);
    __asm__ __volatile__("" : : "r"(p) : "memory");
}
EOF

# ---------- OpenSSH ----------
echo "== 3 编译 OpenSSH =="
cd "$WORK/openssh-$SSH_VER"

# getrrsetbyname: NDK 的 resolv.h 未暴露现代 resolver 结构 → 提供降级实现
# （仅影响 SSHFP/DNS 查询，不影响 sshd/sftp 登录）
python3 - "$WORK/ssh.tgz" <<'PY'
import sys, tarfile
tgz = sys.argv[1]
dst = 'openbsd-compat/getrrsetbyname.c'
with tarfile.open(tgz) as t:
    name = [m.name for m in t.getmembers() if m.name.endswith('openbsd-compat/getrrsetbyname.c')][0]
    orig = t.extractfile(name).read().decode()
stub = '''
#if defined(__ANDROID__)
int
getrrsetbyname(const char *host, unsigned int rrsetflags, unsigned int rrtype,
    unsigned int rrclass, struct rrsetinfo **res)
{
	(void)host; (void)rrsetflags; (void)rrtype; (void)rrclass;
	if (res != NULL)
		*res = NULL;
	return -1;
}
void
freerrset(struct rrsetinfo *rrset)
{
	(void)rrset;
}
#else
'''
anchor = '#include "getrrsetbyname.h"\n'
i = orig.index(anchor) + len(anchor)
open(dst, 'w').write(orig[:i] + stub + orig[i:] + "\n#endif /* __ANDROID__ */\n")
print('getrrsetbyname.c: Android 分支已注入')
PY

make distclean >/dev/null 2>&1 || true
export CC AR=llvm-ar RANLIB=llvm-ranlib
export CFLAGS="-include $COMPAT -Wno-error -Wno-implicit-function-declaration -Wno-deprecated-declarations"

# 预置探测结果（bionic：有 bzero/utimes，无 explicit_bzero/memset_s/futimes；
#  clang 默认把未声明函数当错误，令 autoconf 的探测无法工作 → 直接给定）
export ac_cv_func_bzero=yes ac_cv_func_explicit_bzero=yes ac_cv_func_memset_s=no
export ac_cv_func_futimes=no ac_cv_func_futimesat=no ac_cv_func_utimes=yes
export ac_cv_sizeof_long_int=8
export ac_cv_c_undeclared_builtin_options='-Werror=implicit-function-declaration'

M=/data/adb/modules/sshd_autostart
./configure --host="$HOST" \
  --with-ssl-dir="$SSL_PREFIX" \
  --with-privsep-user=root \
  --without-pam --with-sandbox=no --without-zlib-version-check \
  --disable-utmp --disable-utmpx --disable-wtmp --disable-wtmpx --disable-lastlog \
  --prefix="$M" --sysconfdir="$M/etc" --libexecdir="$M/libexec" \
  --with-privsep-path="$M/empty"

make -j"$(nproc)" sshd sshd-session ssh-keygen scp sftp-server

mkdir -p "$OUT/bin" "$OUT/libexec"
for f in sshd ssh-keygen scp; do [ -f "$f" ] && cp -f "$f" "$OUT/bin/"; done
for f in sshd-session sshd-auth sftp-server; do [ -f "$f" ] && cp -f "$f" "$OUT/libexec/"; done

echo "== 产物 =="
ls -l "$OUT/bin" "$OUT/libexec"
echo "BUILD_DONE"
