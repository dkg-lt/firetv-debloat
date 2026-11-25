#!/system/bin/sh
# GhostLock --exec payload: RAM optimization for account-less Fire TV (AFTKA).
# Disables persistent Amazon bloat system-wide (enabled=2), disables protected
# account-dependent cloud/cast services, disables WebView telemetry service
# component, and disables stock launcher background MediaBrowse/Card components
# while keeping com.amazon.tv.launcher + SettingsActivity + ADM intact.
#
# Fully reversible via revert-ram-optimize.sh.

LOG=/data/local/tmp/gl/04-ram-optimize.log
: > "$LOG"
exec >>"$LOG" 2>&1
echo "=== 04-ram-optimize start ==="
id

disable_persistent_pkg() {
  p=$1
  # Use system-wide `pm disable` (state=2) ONLY — do NOT follow with disable-user
  # which would overwrite state=2 back to state=3 (DISABLED_USER).
  pm disable "$p" 2>&1
  am force-stop --user 0 "$p" 2>/dev/null || am force-stop "$p" 2>/dev/null
  st=$(dumpsys package "$p" | grep -m1 'enabled=' | tr -d '\r')
  echo "PERS $p -> $st"
}

disable_protected_pkg() {
  p=$1
  pm disable-user --user 0 "$p" 2>&1
  if ! pm list packages -d 2>/dev/null | grep -q "^package:$p$"; then
    pm disable "$p" 2>&1
  fi
  am force-stop --user 0 "$p" 2>/dev/null || am force-stop "$p" 2>/dev/null
  st=$(dumpsys package "$p" | grep -m1 'enabled=' | tr -d '\r')
  echo "PROT $p -> $st"
}

disable_comp() {
  c=$1
  pm disable "$c" 2>&1
  echo "COMP $c rc=$?"
}

echo "--- 1. Persistent Amazon apps (enabled=2) ---"
disable_persistent_pkg com.amazon.vizzini
disable_persistent_pkg com.amazon.tcomm
disable_persistent_pkg com.amazon.imp
disable_persistent_pkg com.amazon.whad

echo "--- 2. Protected non-persistent Amazon cloud/cast services ---"
disable_protected_pkg com.amazon.whisperlink.core.android
# KEEP com.amazon.device.messaging ENABLED: com.amazon.tv.launcher/.ui.MainSettingsActivity
# crashes on startup (CacheBustingSyncReceiverTask -> CloudMessagingServiceException) if disabled.
pm enable com.amazon.device.messaging 2>&1
disable_protected_pkg com.fireos.arcus.proxy
disable_protected_pkg com.amazon.diode
disable_protected_pkg com.amazon.sync.service

echo "--- 3. WebView telemetry service component only (keep WebView enabled) ---"
disable_comp com.amazon.webview.chromium/com.amazon.webview.metrics.service.AWVMetricsService

echo "--- 4. Stock launcher background services/receivers (keep package & SettingsActivity enabled) ---"
# NEVER call `pm enable com.amazon.tv.launcher` here (it resets component overrides).
disable_comp com.amazon.tv.launcher/com.amazon.tv.mediabrowse.service.MediaBrowseServiceImpl
disable_comp com.amazon.tv.launcher/com.amazon.tv.launcher.autoplay.AutoPlaybackService
disable_comp com.amazon.tv.launcher/com.amazon.firecard.deviceagent.CardDeviceAgent
disable_comp com.amazon.tv.launcher/com.amazon.firecard.deviceagent.service.LocalProviderService
disable_comp com.amazon.tv.launcher/com.amazon.tv.launcher.content.SkillConnectionService
disable_comp com.amazon.tv.launcher/com.amazon.tv.mediabrowse.CacheBustingAsynchronousReceiver
disable_comp com.amazon.tv.launcher/com.amazon.tv.mediabrowse.util.MediaBrowseCacheModificationBroadcastReceiver
disable_comp com.amazon.tv.launcher/com.amazon.tv.cardflow.AppStoreReceiver
disable_comp com.amazon.tv.launcher/com.amazon.tv.launcher.content.ComradeReceiver
disable_comp com.amazon.tv.launcher/com.amazon.tv.launcher.util.AppRecencyReceiver
disable_comp com.amazon.tv.launcher/com.amazon.tv.launcher.ExperienceChangedReceiver
disable_comp com.amazon.tv.launcher/com.amazon.tv.launcher.MBRoutingInfoChangedReceiver
disable_comp com.amazon.tv.launcher/com.amazon.tv.csm.directives.UIControllerDirectiveReceiver
disable_comp com.amazon.tv.launcher/com.amazon.tv.csm.directives.DirectiveReceiver
disable_comp com.amazon.tv.launcher/com.amazon.tv.launcher.rvpcal.RvpCalDirectiveReceiver
disable_comp com.amazon.tv.launcher/com.amazon.tv.launcher.content.FBAReceiver

# Ensure stock HOME stays disabled and SettingsActivity stays enabled
pm disable-user --user 0 com.amazon.tv.launcher/com.amazon.tv.launcher.ui.HomeActivity_vNext 2>&1
pm enable com.amazon.tv.launcher/com.amazon.tv.launcher.ui.SettingsActivity 2>&1
am force-stop com.amazon.tv.launcher 2>&1

echo "--- 5. Verify invariants ---"
settings put global com.amazon.tv.oobe.RESTRICT_REMOTE_BUTTONS 0
cmd package resolve-activity --brief -a android.intent.action.MAIN -c android.intent.category.HOME
pm list packages -d | wc -l

sync
echo "=== 04-ram-optimize done ==="
exit 0
