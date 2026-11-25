#!/system/bin/sh
# GhostLock --exec payload: Revert Fire TV BLE Penny Remote KeyLayout override.

LOG=/data/local/tmp/gl/revert-remap-buttons.log
: > "$LOG"
exec >>"$LOG" 2>&1
echo "=== revert-remap-buttons start ==="
id

rm -f /data/system/devices/keylayout/Vendor_0171_Product_041e_Version_0038.kl
ls -la /data/system/devices/keylayout 2>&1 || true
sync
echo "=== revert-remap-buttons done ==="
exit 0
