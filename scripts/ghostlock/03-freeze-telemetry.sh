#!/system/bin/sh
# GhostLock --exec payload: freeze Fire TV telemetry/logging agents and
# account-dependent Amazon apps. Package states persist across reboots.

LOG=/data/local/tmp/gl/03-freeze-telemetry.log
: > "$LOG"
exec >>"$LOG" 2>&1
echo "=== 03-freeze-telemetry start ==="
id

disable_pkg() {
  p=$1
  pm disable-user --user 0 "$p" 2>/dev/null
  if ! pm list packages -d 2>/dev/null | grep -q "^package:$p$"; then
    pm disable --user 0 "$p" 2>/dev/null
  fi
  am force-stop --user 0 "$p" 2>/dev/null || am force-stop "$p" 2>/dev/null
  if pm list packages -d 2>/dev/null | grep -q "^package:$p$"; then
    echo "OK   $p"
  else
    echo "FAIL $p"
  fi
}

# Event/telemetry pipeline, log collection, crash upload, usage stats, metrics
for p in \
  com.amazon.ceviche \
  com.amazon.adep \
  com.amazon.logan \
  com.amazon.device.rdmapplication \
  com.fireos.sdk.ftve.addp \
  com.amazon.device.logmanager \
  com.amazon.device.crashmanager \
  com.fireos.usagestats.proxy \
  com.amazon.ftvads.deeplinking \
  com.amazon.device.metrics \
  com.amazon.tv.fw.metrics \
  com.amazon.aria \
  com.amazon.perfc \
  com.amazon.perfcollection \
  com.amazon.d3 \
  com.amazon.dp.logger; do
  disable_pkg "$p"
done

# Account-dependent Amazon apps (useless without an Amazon account)
for p in \
  com.amazon.alexamediaplayer.runtime.ftv \
  com.amazon.spiderpork \
  com.amazon.bueller.photos \
  com.amazon.kso.blackbird \
  com.amazon.smarthomemapviewapp \
  com.amazon.venezia \
  com.amazon.device.sale.service; do
  disable_pkg "$p"
done

echo "--- disabled count ---"
pm list packages -d | wc -l

sync
echo "=== 03-freeze-telemetry done ==="
exit 0
