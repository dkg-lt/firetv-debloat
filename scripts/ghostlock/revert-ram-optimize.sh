#!/system/bin/sh
# GhostLock --exec payload: REVERT 04-ram-optimize.sh changes.
# Restores protected/persistent packages and components touched by 04-ram-optimize.sh,
# while preserving OOBE disable, OTA blocks, firehomestarter disable, and Fire TV Launcher HOME.

LOG=/data/local/tmp/gl/revert-ram-optimize.log
: > "$LOG"
exec >>"$LOG" 2>&1
echo "=== revert-ram-optimize start ==="
id

echo "--- 1. Re-enable persistent & protected packages ---"
for p in \
  com.amazon.vizzini \
  com.amazon.tcomm \
  com.amazon.imp \
  com.amazon.whad \
  com.amazon.whisperlink.core.android \
  com.amazon.device.messaging \
  com.fireos.arcus.proxy \
  com.amazon.diode \
  com.amazon.sync.service; do
  pm enable "$p" 2>&1
done

echo "--- 2. Re-enable WebView metrics component ---"
pm enable com.amazon.webview.chromium/com.amazon.webview.metrics.service.AWVMetricsService 2>&1

echo "--- 3. Re-enable stock launcher background components (keep HomeActivity_vNext disabled) ---"
for c in \
  com.amazon.tv.launcher/com.amazon.tv.mediabrowse.service.MediaBrowseServiceImpl \
  com.amazon.tv.launcher/com.amazon.tv.launcher.autoplay.AutoPlaybackService \
  com.amazon.tv.launcher/com.amazon.firecard.deviceagent.CardDeviceAgent \
  com.amazon.tv.launcher/com.amazon.firecard.deviceagent.service.LocalProviderService \
  com.amazon.tv.launcher/com.amazon.tv.launcher.content.SkillConnectionService \
  com.amazon.tv.launcher/com.amazon.tv.mediabrowse.CacheBustingAsynchronousReceiver \
  com.amazon.tv.launcher/com.amazon.tv.mediabrowse.util.MediaBrowseCacheModificationBroadcastReceiver \
  com.amazon.tv.launcher/com.amazon.tv.cardflow.AppStoreReceiver \
  com.amazon.tv.launcher/com.amazon.tv.launcher.content.ComradeReceiver \
  com.amazon.tv.launcher/com.amazon.tv.launcher.util.AppRecencyReceiver \
  com.amazon.tv.launcher/com.amazon.tv.launcher.ExperienceChangedReceiver \
  com.amazon.tv.launcher/com.amazon.tv.launcher.MBRoutingInfoChangedReceiver \
  com.amazon.tv.launcher/com.amazon.tv.csm.directives.UIControllerDirectiveReceiver \
  com.amazon.tv.launcher/com.amazon.tv.csm.directives.DirectiveReceiver \
  com.amazon.tv.launcher/com.amazon.tv.launcher.rvpcal.RvpCalDirectiveReceiver \
  com.amazon.tv.launcher/com.amazon.tv.launcher.content.FBAReceiver; do
  pm enable "$c" 2>&1
done
pm disable-user --user 0 com.amazon.tv.launcher/com.amazon.tv.launcher.ui.HomeActivity_vNext 2>&1
pm enable com.amazon.tv.launcher/com.amazon.tv.launcher.ui.SettingsActivity 2>&1

echo "--- 4. Verify HOME ---"
cmd package resolve-activity --brief -a android.intent.action.MAIN -c android.intent.category.HOME
sync
echo "=== revert-ram-optimize done ==="
exit 0
