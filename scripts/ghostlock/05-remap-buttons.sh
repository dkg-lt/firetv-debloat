#!/system/bin/sh
# GhostLock --exec payload: Override Fire TV BLE Penny Remote (0171:041e v0038)
# app shortcut buttons (744-747: Prime Video, Netflix, Disney+, Amazon Music)
# to F1-F4 via /data/system/devices/keylayout/ so FireTVKeyPolicyManager does
# not intercept them and Fire TV Launcher's InputKeyService can remap them freely.
#
# Fully reversible via revert-remap-buttons.sh.

LOG=/data/local/tmp/gl/05-remap-buttons.log
: > "$LOG"
exec >>"$LOG" 2>&1
echo "=== 05-remap-buttons start ==="
id

DIR=/data/system/devices/keylayout
KL="$DIR/Vendor_0171_Product_041e_Version_0038.kl"

mkdir -p "$DIR"
chmod 755 /data/system/devices "$DIR"
chown root:root /data/system/devices "$DIR"

cat > "$KL" <<'EOF'
# Override for Amazon Fire TV BLE Penny Remote (vendor 0171, product 041e, version 0038)
# Maps the 4 branded app buttons (744-747) to F1-F4 so they bypass FireTVKeyPolicyManager
# and can be remapped to any app or action in Fire TV Launcher.

key 116   POWER
key 217   ALEXA

key 96    DPAD_CENTER
key 103   DPAD_UP
key 105   DPAD_LEFT
key 106   DPAD_RIGHT
key 108   DPAD_DOWN

key 172   HOME
key 158   BACK
key 139   MENU

key 113   VOLUME_MUTE
key 114   VOLUME_DOWN
key 115   VOLUME_UP

key 168   MEDIA_REWIND
key 208   MEDIA_FAST_FORWARD
key 164   MEDIA_PLAY_PAUSE

key 362   LIVE_TV

# Remapped App Keys (was APP_1..APP_4)
key 744   F1
key 745   F2
key 746   F3
key 747   F4
EOF

chmod 644 "$KL"
chown root:root "$KL"
chcon u:object_r:system_data_file:s0 /data/system/devices "$DIR" "$KL" 2>/dev/null || true

ls -laZ "$KL"
sync
echo "=== 05-remap-buttons done ==="
exit 0
