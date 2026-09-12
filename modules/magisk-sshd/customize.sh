#!/system/bin/sh
# Magisk installer hook
SKIPUNZIP=0
set_perm_recursive "$MODPATH" 0 0 0755 0644
set_perm "$MODPATH/service.sh" 0 0 0755
set_perm "$MODPATH/action.sh" 0 0 0755
set_perm "$MODPATH/common.sh" 0 0 0755
set_perm_recursive "$MODPATH/bin" 0 0 0755 0755
set_perm_recursive "$MODPATH/libexec" 0 0 0755 0755
mkdir -p "$MODPATH/etc" "$MODPATH/empty"
chmod 700 "$MODPATH/etc"
ui_print "- sshd_autostart: bundled OpenSSH (port 22)"
ui_print "- 请把公钥追加到: $MODPATH/etc/authorized_keys"
