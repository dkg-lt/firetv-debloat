#!/system/bin/sh
# GhostLock --exec payload: make Fire TV Launcher (com.dkg.tvlauncher) the
# permanent Fire TV HOME. Run AFTER installing com.dkg.tvlauncher and disarming OOBE.
# Package/component states set here persist across reboots.

LOG=/data/local/tmp/gl/02-set-home.log
: > "$LOG"
exec >>"$LOG" 2>&1
echo "=== 02-set-home start ==="
id
set -x

# Verify Fire TV Launcher is installed before disabling stock HOME.
if ! pm path com.dkg.tvlauncher >/dev/null 2>&1; then
  echo "ERROR: com.dkg.tvlauncher is not installed! Aborting to avoid bricking HOME."
  exit 1
fi

# Disable Fire OS HomeStarter (intercepts HOME via fireos.intent.category.MAIN_HOME).
pm disable-user --user 0 com.amazon.firehomestarter

# IMPORTANT ORDERING: pm enable <pkg> resets component overrides to default,
# so enable com.amazon.tv.launcher BEFORE disabling HomeActivity_vNext.
# Keep the stock launcher package enabled so Fire TV Settings continues to work.
pm enable com.amazon.tv.launcher
pm disable-user --user 0 com.amazon.tv.launcher/com.amazon.tv.launcher.ui.HomeActivity_vNext
pm enable com.amazon.tv.launcher/com.amazon.tv.launcher.ui.SettingsActivity

# Pin Fire TV Launcher as default HOME.
pm enable com.dkg.tvlauncher
pm enable com.dkg.tvlauncher/.MainActivity
cmd package set-home-activity --user 0 com.dkg.tvlauncher/.MainActivity

echo "--- HOME resolve ---"
cmd package resolve-activity --brief -a android.intent.action.MAIN -c android.intent.category.HOME

am start -n com.dkg.tvlauncher/.MainActivity
sleep 2
dumpsys window | grep mCurrentFocus

sync
echo "=== 02-set-home done ==="
exit 0
