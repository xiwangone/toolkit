#!/system/bin/sh
# Magisk late_start service: bring sshd up once the system has booted.
MODDIR=${0%/*}
. "$MODDIR/common.sh"
until [ "$(getprop sys.boot_completed)" = "1" ]; do sleep 2; done
sleep 5
start_sshd
