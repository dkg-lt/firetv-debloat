#!/usr/bin/env bash
# Re-enable all unprotected packages disabled by scripts/debloat-shell.sh.
# Does not touch root-disabled protected packages (OOBE, OTA, firehomestarter, etc.).
#
# Usage:
#   FIRE_TV_ADDR=192.168.1.50:5555 ./scripts/revert-shell.sh
#   ./scripts/revert-shell.sh 192.168.1.50:5555

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

PACKAGES=(
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

for pkg in "${PACKAGES[@]}"; do
  "${ADB_CMD[@]}" shell pm enable "$pkg" >/dev/null 2>&1 && echo "ENABLED   $pkg" || true
done
