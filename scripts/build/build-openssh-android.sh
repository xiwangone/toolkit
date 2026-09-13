#!/usr/bin/env bash
# 交叉编译 OpenSSH（aarch64 / Android，NDK clang）—— 本地(WSL/Linux)与 CI 共用
#
# 用法: build-openssh-android.sh <NDK_ROOT> <WORK_DIR> <OUT_DIR> [API_LEVEL]
#   <NDK_ROOT>  NDK 根目录（含 toolchains/llvm/prebuilt/linux-x86_64）
#   <WORK_DIR>  下载/编译工作目录（放本地盘，勿用 /mnt 之类慢挂载）
#   <OUT_DIR>   产物输出（生成 bin/ 与 libexec/）
#   [API_LEVEL] 目标 API（默认 26）
#
# 说明：bionic 与 glibc 差异较多，本脚本集中处理（均为编译期适配）：
#   1) __sentinel__ 不存在、_PATH_MAILDIR 无默认值
#   2) explicit_bzero 到 API 30 才有声明 → 提供等价实现
#   3) getpwuid/getpwnam：Android 无 passwd 数据库，bionic 返回 NULL 或字段残缺，
#      OpenSSH 直接解引用会段错误 → 调用点改名 + 补齐字段（必须，否则 sshd/ssh-keygen 崩）
#   4) bzero 在 bionic 是宏、memset_s/futimes 不可用 → 预置 configure 探测结果
#   5) utmp/utmpx/wtmp/lastlog 在 Android 无 → configure 关闭
#   6) getrrsetbyname：NDK 的 resolv.h 未暴露现代 resolver 结构 → 降级实现
#   7) smult_curve25519_ref.c 的 select() 与系统声明冲突 → 改名
set -euo pipefail

NDK="${1:?need NDK root}"
WORK="${2:?need work dir}"
OUT="${3:?need out dir}"
API="${4:-26}"
HOST=aarch64-linux-android
CC="${HOST}${API}-clang"
OPENSSL_VER=3.0.15
SSH_VER=9.9p2
MODDIR=/data/adb/modules/sshd_autostart

export ANDROID_NDK_ROOT="$NDK"
export PATH="$NDK/toolchains/llvm/prebuilt/linux-x86_64/bin:$PATH"
mkdir -p "$WORK" "$OUT"
cd "$WORK"
command -v "$CC" >/dev/null || { echo "找不到 $CC（NDK 路径或 prebuilt 架构不符）" >&2; exit 1; }

echo "== 0 工具链 =="
"$CC" --version | head -2

# ---------- 源码 ----------
echo "== 1 依赖源码 =="
[ -f ssl.tgz ] || curl -sL --retry 3 -o ssl.tgz "https://github.com/openssl/openssl/releases/download/openssl-$OPENSSL_VER/openssl-$OPENSSL_VER.tar.gz"
[ -f ssh.tgz ] || curl -sL --retry 3 -o ssh.tgz "https://cdn.openbsd.org/pub/OpenBSD/OpenSSH/portable/openssh-$SSH_VER.tar.gz"
[ -d "openssl-$OPENSSL_VER" ] || tar xzf ssl.tgz
rm -rf "openssh-$SSH_VER"          # 每次从干净源码开始（下面的补丁是幂等的）
tar xzf ssh.tgz

# ---------- OpenSSL（静态，编一次即可） ----------
SSL_PREFIX="$WORK/ssl"
if [ ! -f "$SSL_PREFIX/lib/libcrypto.a" ]; then
  echo "== 2 编译 OpenSSL =="
  cd "$WORK/openssl-$OPENSSL_VER"
  ./Configure android-arm64 -D__ANDROID_API__="$API" no-shared no-tests --prefix="$SSL_PREFIX"
  make -j"$(nproc)"
  make install_sw
fi
ls -l "$SSL_PREFIX/lib/libcrypto.a"

# ---------- bionic 兼容头（-include 注入所有编译单元） ----------
COMPAT="$WORK/bionic_compat.h"
cat > "$COMPAT" <<'EOF'
#ifndef __sentinel__
#define __sentinel__(x)
#endif
#include <string.h>
#include <strings.h>
#include <pwd.h>
#ifndef _PATH_MAILDIR
#define _PATH_MAILDIR "/data/local/tmp"
#endif
/* bionic 到 API 30 才有 explicit_bzero 声明 */
static inline void explicit_bzero(void *p, size_t n) {
    memset(p, 0, n);
    __asm__ __volatile__("" : : "r"(p) : "memory");
}
/* Android 无 passwd 数据库：bionic 的 getpwuid/getpwnam 返回 NULL 或字段残缺，
   直接使用会段错误。统一返回字段完整的合成条目（源码调用点已改名到此）。 */
static inline void
__android_uitoa(unsigned v, char *buf, size_t n)
{
	size_t i = 0, k;
	char t[12];
	do { t[i++] = (char)('0' + (v % 10)); v /= 10; } while (v != 0 && i < sizeof(t));
	if (i + 1 > n) i = (n > 1) ? (n - 1) : 0;
	for (k = 0; k < i; k++) buf[k] = t[i - 1 - k];
	buf[i] = '\0';
}
static inline struct passwd *
__android_pw_make(uid_t uid)
{
	static struct passwd fixed;
	static char namebuf[24];
	memset(&fixed, 0, sizeof(fixed));
	fixed.pw_uid = uid;
	fixed.pw_gid = uid;
	__android_uitoa((unsigned)uid, namebuf, sizeof(namebuf));
	fixed.pw_name = (uid == 0) ? (char *)"root" : namebuf;
	fixed.pw_passwd = (char *)"x";
	fixed.pw_gecos = (char *)"";
	fixed.pw_dir = (char *)"/data/local/tmp";
	fixed.pw_shell = (char *)"/system/bin/sh";
	return &fixed;
}
static inline struct passwd *ssh_getpwuid(uid_t uid) { return __android_pw_make(uid); }
static inline struct passwd *ssh_getpwnam(const char *n) {
	uid_t uid = (n != NULL && strcmp(n, "root") == 0) ? (uid_t)0 : (uid_t)-1;
	return __android_pw_make(uid);
}
EOF

# ---------- 源码补丁 ----------
echo "== 3 源码适配 =="
cd "$WORK/openssh-$SSH_VER"
python3 - <<'PY'
import re, os

# (a) getrrsetbyname：NDK 的 resolv.h 未暴露现代 resolver 结构 → 降级实现
p = 'openbsd-compat/getrrsetbyname.c'
orig = open(p).read()
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
open(p, 'w').write(orig[:i] + stub + orig[i:] + "\n#endif /* __ANDROID__ */\n")

# (b) curve25519 ref 的 select() 与系统声明冲突 → 改名
p = 'smult_curve25519_ref.c'
s = open(p).read()
s = s.replace('static void select(unsigned int p[64]', 'static void c25519_select(unsigned int p[64]')
s = re.sub(r'(?<![A-Za-z0-9_])select\((xzmb|xzm1)', r'c25519_select(\1', s)
open(p, 'w').write(s)

# (c) 全部 .c 中 getpwuid/getpwnam 调用 → 我们的兜底实现
cnt = 0
for root, dirs, files in os.walk('.'):
    for f in files:
        if not f.endswith('.c'):
            continue
        fp = os.path.join(root, f)
        t = open(fp, errors='ignore').read()
        n = re.sub(r'(?<![A-Za-z0-9_])getpwuid\s*\(', 'ssh_getpwuid(', t)
        n = re.sub(r'(?<![A-Za-z0-9_])getpwnam\s*\(', 'ssh_getpwnam(', n)
        if n != t:
            open(fp, 'w').write(n)
            cnt += 1
print('c files patched:', cnt)
PY

# ---------- configure / make ----------
echo "== 4 编译 OpenSSH =="
export CC AR=llvm-ar RANLIB=llvm-ranlib
export CFLAGS="-include $COMPAT -Wno-error -Wno-implicit-function-declaration -Wno-deprecated-declarations"
export ac_cv_func_bzero=yes ac_cv_func_explicit_bzero=yes ac_cv_func_memset_s=no
export ac_cv_func_futimes=no ac_cv_func_futimesat=no ac_cv_func_utimes=yes
export ac_cv_sizeof_long_int=8
export ac_cv_c_undeclared_builtin_options='-Werror=implicit-function-declaration'

./configure --host="$HOST" \
  --with-ssl-dir="$SSL_PREFIX" \
  --with-privsep-user=root \
  --without-pam --with-sandbox=no --without-zlib-version-check --without-hardening \
  --disable-utmp --disable-utmpx --disable-wtmp --disable-wtmpx --disable-lastlog \
  --prefix="$MODDIR" --sysconfdir="$MODDIR/etc" --libexecdir="$MODDIR/libexec" \
  --with-privsep-path="$MODDIR/empty"

make -j"$(nproc)" sshd sshd-session ssh-keygen scp sftp-server

mkdir -p "$OUT/bin" "$OUT/libexec"
for f in sshd ssh-keygen scp; do [ -f "$f" ] && cp -f "$f" "$OUT/bin/"; done
for f in sshd-session sshd-auth sftp-server; do [ -f "$f" ] && cp -f "$f" "$OUT/libexec/"; done

echo "== 产物 =="
ls -l "$OUT/bin" "$OUT/libexec"
echo "BUILD_DONE"
