#!/usr/bin/env bash
# No-root fallback workaround for the Fire TV OOBE registration loop.
# Only needed if you cannot run GhostLock (01-disarm-oobe.sh).
#
# Deploys a tiny on-device watchdog that brings your launcher back to the front
# whenever com.amazon.tv.oobe steals focus, and keeps RESTRICT_REMOTE_BUTTONS=0.
# Survives ADB disconnect and standby, but NOT reboot.
#
# Stop with: adb shell 'pkill -f "[o]obe-watchdog.sh"'
#
# Usage:
#   FIRE_TV_ADDR=192.168.1.50:5555 ./scripts/oobe-watchdog.sh
#   ./scripts/oobe-watchdog.sh 192.168.1.50:5555

set -eu
export MSYS2_ARG_CONV_EXCL='*'

ADB="${ADB:-adb}"
DEV="${1:-${FIRE_TV_ADDR:-}}"
LAUNCHER="${LAUNCHER_COMPONENT:-com.dkg.tvlauncher/.MainActivity}"

if [ -n "$DEV" ]; then
  "$ADB" connect "$DEV" >/dev/null
  ADB_CMD=("$ADB" -s "$DEV")
else
  ADB_CMD=("$ADB")
fi

"${ADB_CMD[@]}" shell "settings put global com.amazon.tv.oobe.RESTRICT_REMOTE_BUTTONS 0"
"${ADB_CMD[@]}" shell 'pkill -f "[o]obe-watchdog.sh" 2>/dev/null || true'

"${ADB_CMD[@]}" shell "cat > /data/local/tmp/oobe-watchdog.sh << 'EOF'
#!/system/bin/sh
LAUNCHER=$LAUNCHER

bounce() {
  am start -n \"\$LAUNCHER\" >/dev/null 2>&1
  settings put global com.amazon.tv.oobe.RESTRICT_REMOTE_BUTTONS 0
}

settings put global com.amazon.tv.oobe.RESTRICT_REMOTE_BUTTONS 0
dumpsys window 2>/dev/null | grep -q 'mCurrentFocus=.*com.amazon.tv.oobe' && bounce

logcat -v brief ActivityManager:I ActivityTaskManager:I '*:S' 2>/dev/null | while read -r line; do
  case \"\$line\" in
    *'cmp=com.amazon.tv.oobe/'*) bounce ;;
  esac
done &

while true; do
  sleep 10
  settings put global com.amazon.tv.oobe.RESTRICT_REMOTE_BUTTONS 0
  dumpsys window 2>/dev/null | grep -q 'mCurrentFocus=.*com.amazon.tv.oobe' && bounce
done
EOF
chmod 755 /data/local/tmp/oobe-watchdog.sh"

"${ADB_CMD[@]}" shell "nohup /system/bin/sh /data/local/tmp/oobe-watchdog.sh >/dev/null 2>&1 & am start -n $LAUNCHER >/dev/null 2>&1; sleep 1; pgrep -f '[o]obe-watchdog.sh' >/dev/null && echo 'watchdog running' || echo 'watchdog NOT running'"
