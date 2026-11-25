#!/system/bin/sh
# GhostLock --exec payload: permanently disarm the Fire TV OOBE registration loop
# and keep OTA updates blocked. Runs as uid 0; PackageManager changes persist
# across reboots even though temp-root does not.

LOG=/data/local/tmp/gl/01-disarm-oobe.log
: > "$LOG"
exec >>"$LOG" 2>&1
echo "=== 01-disarm-oobe start ==="
id
set -x

# Remove temporary OOBE watchdog if previously installed.
pkill -f "[o]obe-watchdog.sh" 2>/dev/null || true
rm -f /data/local/tmp/oobe-watchdog.sh

# Disable OOBE at package level (persistent).
pm disable-user --user 0 com.amazon.tv.oobe
if ! pm list packages -d 2>/dev/null | grep -q '^package:com.amazon.tv.oobe$'; then
  pm disable --user 0 com.amazon.tv.oobe
fi
if ! pm list packages -d 2>/dev/null | grep -q '^package:com.amazon.tv.oobe$'; then
  pm hide --user 0 com.amazon.tv.oobe
fi

# Block OTA updates and metrics.
pm disable-user --user 0 com.amazon.device.software.ota
pm disable com.amazon.device.software.ota.override
pm disable com.amazon.client.metrics
pm disable-user --user 0 com.amazon.sneakpeek

# OOBE sets this to 1 while active, which blocks remote D-pad input.
settings put global com.amazon.tv.oobe.RESTRICT_REMOTE_BUTTONS 0

echo "--- oobe state ---"
dumpsys package com.amazon.tv.oobe | grep -E 'enabled=|hidden=|suspended=' | head -3
echo "--- disabled oobe/ota ---"
pm list packages -d | grep -E 'oobe|ota|sneakpeek|metrics'

sync
echo "=== 01-disarm-oobe done ==="
exit 0
