#!/system/bin/sh
# Magisk action button: toggle sshd and show status.
MODDIR=${0%/*}
. "$MODDIR/common.sh"
if is_running; then
    stop_sshd
else
    start_sshd
fi
status_sshd
