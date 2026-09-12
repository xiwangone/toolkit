#!/system/bin/sh
# Shared helpers (bundled OpenSSH build; no external dependencies).
MODDIR="${MODDIR:-/data/adb/modules/sshd_autostart}"
ETC="$MODDIR/etc"
BIN="$MODDIR/bin"
SSHD="$BIN/sshd"
KEYGEN="$BIN/ssh-keygen"
PIDFILE="$MODDIR/sshd.pid"
LOG="$MODDIR/sshd.log"
PORT=22

log() { echo "[$(date '+%m-%d %H:%M:%S')] $*" >> "$LOG"; }

is_running() {
    [ -f "$PIDFILE" ] || return 1
    pid=$(cat "$PIDFILE" 2>/dev/null)
    [ -n "$pid" ] && [ -d "/proc/$pid" ] && return 0
    return 1
}

ensure_dirs() {
    mkdir -p "$ETC" "$MODDIR/empty"
    chmod 700 "$ETC" 2>/dev/null
    [ -f "$ETC/ssh_host_ed25519_key" ] || "$KEYGEN" -q -t ed25519 -f "$ETC/ssh_host_ed25519_key" -N '' 2>>"$LOG"
    [ -f "$ETC/authorized_keys" ] || : > "$ETC/authorized_keys"
    chmod 600 "$ETC/authorized_keys" "$ETC"/ssh_host_*_key 2>/dev/null
}

start_sshd() {
    if is_running; then log "start: already running (pid $(cat "$PIDFILE"))"; return 0; fi
    [ -x "$SSHD" ] || { log "start: missing bundled sshd at $SSHD"; return 1; }
    ensure_dirs
    "$SSHD" -f "$ETC/sshd_config" -E "$LOG" -o "PidFile=$PIDFILE" || { log "start: sshd exited non-zero"; return 1; }
    sleep 1
    if is_running; then log "start: ok (pid $(cat "$PIDFILE"), port $PORT)"; return 0; fi
    log "start: failed"; return 1
}

stop_sshd() {
    if ! is_running; then log "stop: not running"; return 0; fi
    pid=$(cat "$PIDFILE"); kill "$pid" 2>/dev/null; sleep 1; rm -f "$PIDFILE"; log "stop: killed $pid"
}

status_sshd() {
    if is_running; then
        echo "sshd: RUNNING (pid $(cat "$PIDFILE"), port $PORT)"
        echo "keys: $ETC/authorized_keys"
    else
        echo "sshd: STOPPED (port $PORT)"
    fi
}
