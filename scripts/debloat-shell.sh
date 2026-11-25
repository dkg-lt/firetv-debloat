#!/usr/bin/env bash
# Disable unprotected Amazon bloatware packages over ADB shell (no root needed).
# Uses `pm disable-user --user 0`, which is 100% reversible via revert-shell.sh
# and persists across reboots.
#
# Usage:
#   FIRE_TV_ADDR=192.168.1.50:5555 ./scripts/debloat-shell.sh
#   ./scripts/debloat-shell.sh 192.168.1.50:5555

set -eu
export MSYS2_ARG_CONV_EXCL='*'

ADB="${ADB:-adb}"
DEV="${1:-${FIRE_TV_ADDR:-}}"

if [ -n "$DEV" ]; then
  "$ADB" connect "$DEV"
  ADB_CMD=("$ADB" -s "$DEV")
else
  ADB_CMD=("$ADB")
fi

# Unprotected Amazon bloatware, cloud/sync churners, Alexa, Matter, OTA, ads, tutorials.
# Protected packages (OOBE, firehomestarter, telemetry agents, whisperlink, etc.) are
# handled separately by scripts/ghostlock/*.sh.
PACKAGES=(
  # Baseline Amazon bloat & unused services
  com.amazon.bueller.music
  com.amazon.csm.htmlruntime
  com.amazon.dcp
  com.amazon.firebat
  com.amazon.gamehub
  com.amazon.hybridadidservice
  com.amazon.kindleautomatictimezone
  com.amazon.minitv.android.app
  com.amazon.notification
  com.amazon.ods.kindleconnect
  com.amazon.prism.android.service
  com.amazon.recess
  com.amazon.shoptv.client
  com.amazon.shoptv.firetv.client
  com.amazon.stillwatching.activity
  com.amazon.storm.lightning.tutorial
  com.amazon.tahoe
  com.amazon.tmm.tutorial
  com.amazon.tv.livetv
  com.amazon.uxnotification
  com.amazon.vizzini.ftvcds
  com.amazon.wirelessmetrics.service
  com.android.nfc

  # RAM optimization: background/cast/cloud/sync/Alexa/Matter/ACR/OTA
  com.amazon.aca
  com.amazon.alexa.datastore.app
  com.amazon.alexa.externalmediaplayer.fireos
  com.amazon.alexadirectivebrokerservice
  com.amazon.alta.h2clientservice
  com.amazon.ftv.profilepicker
  com.amazon.sharingservice.android.client.proxy
  com.amazon.sync.provider.ipc
  com.amazon.tv.acr
  com.amazon.tv.alexaalerts
  com.amazon.tv.alexanotifications
  com.amazon.tv.ffsprovisioneeclient
  com.amazon.tv.forcedotaupdater.v2
  com.amazon.tv.matter
  com.amazon.tv.mattercohost
  com.amazon.tv.ottssocompanionapp
  com.amazon.uxcontrollerservice
  com.amazon.whisperjoin.middleware.np
  com.amazon.wifilocker
  com.android.providers.tv
)

ok=0
skip=0
for pkg in "${PACKAGES[@]}"; do
  if "${ADB_CMD[@]}" shell pm disable-user --user 0 "$pkg" >/dev/null 2>&1; then
    echo "DISABLED  $pkg"
    ok=$((ok + 1))
  else
    echo "SKIPPED   $pkg (not installed or protected)"
    skip=$((skip + 1))
  fi
done

echo "--- Done: $ok disabled, $skip skipped ---"
echo "Total disabled packages on device: $("${ADB_CMD[@]}" shell pm list packages -d | wc -l)"
