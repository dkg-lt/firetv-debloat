# Fire TV Debloat & Fire TV Launcher

Everything needed to debloat an **Amazon Fire TV Stick 4K Max 1st Gen (`kara`, Fire OS 7.7.1.3)** without an Amazon account, replace the stock HOME with a lightweight custom **Fire TV Launcher** (`com.dkg.tvlauncher`), cut idle background RAM usage, and remap the 4 branded remote app buttons (Prime Video, Netflix, Disney+, Amazon Music) to any installed app or action.

> **Disclaimer:** Tested on Fire TV Stick 4K Max 1st Gen (`AFTKA` / `kara`, Fire OS 7.7.1.3, Android 9). Package disabling uses `pm disable-user` / `pm disable` (100% reversible — no `pm uninstall`). Do not blindly run on unrelated Fire OS versions without checking package names first.

---

## What's Included

```text
firetv-debloat/
├─ launcher/                         # Fire TV Launcher (com.dkg.tvlauncher) Android Gradle project
├─ config/
│  └─ launcher-config.json           # Recommended runtime config (stats_pill, low-RAM toggles)
└─ scripts/
   ├─ debloat-shell.sh               # Disable unprotected Amazon bloat via ADB (no root)
   ├─ revert-shell.sh                # Re-enable shell-disabled packages
   ├─ oobe-watchdog.sh               # No-root fallback if OOBE registration loop appears
   ├─ pack-payloads.ps1 / .sh        # Pack scripts/ghostlock/*.sh into Unix-LF .tar payloads
   └─ ghostlock/
      ├─ 01-disarm-oobe.sh           # Root: permanently disable OOBE + block OTA updates
      ├─ 02-set-home.sh              # Root: disable firehomestarter & stock HOME, pin Fire TV Launcher
      ├─ 03-freeze-telemetry.sh      # Root: disable protected telemetry, logging & account-only apps
      ├─ 04-ram-optimize.sh          # Root: disable persistent/protected bloat & stock launcher services
      ├─ 05-remap-buttons.sh         # Root: override BLE Penny remote keys 744–747 -> F1–F4
      ├─ revert-ram-optimize.sh      # Root: revert 04-ram-optimize.sh
      └─ revert-remap-buttons.sh     # Root: revert 05-remap-buttons.sh
```

### Fire TV Launcher (`com.dkg.tvlauncher`)

Forked from [CleanYourTV 3.6](https://github.com/Gathin23/cleanyourtv) (MIT) with Fire TV–focused additions:
- **RAM & Storage stats pill (`stats_pill`)** — compact live `RAM total / free` and `Storage total / free` bars under the top-right pills.
- **On-TV Remote Button Remapper** (`RemoteButtonsActivity` + `InputKeyService`) — bind both **Tap** and **Hold (0.5 s)** for all 4 branded remote buttons (`F1`–`F4`) to any installed app or system action. Accessible via **Hold OK on Settings pill → Remote buttons** or **Launcher settings → Remote buttons**.
- **Low-memory footprint (~49–68 MB PSS)** with `ambient_glow` and `module_cards` disabled and built-in `onTrimMemory` handling.

---

## Prerequisites

1. **ADB** (`platform-tools`) with wireless debugging enabled on the Fire TV (`Settings → My Fire TV → Developer Options → ADB Debugging`).
2. **JDK 17** and **Android SDK Platform 34 / Build Tools 34.0.0** (to build `launcher/`).
3. **[GhostLock 4.14](https://github.com/R0rt1z2/GhostLock)** (CVE-2026-43499 one-shot temp-root for `kara` 4.14 kernels) — only needed to modify Fire OS–protected packages (`com.amazon.tv.oobe`, `com.amazon.firehomestarter`, telemetry agents, etc.). Root does not survive reboot, but PackageManager states and `/data/system/devices/keylayout/` overrides do.

---

## Step-by-Step Setup (Safe Order)

> **Never disable the stock HOME component or `firehomestarter` before installing and verifying Fire TV Launcher.**

### 1. Build & Install Fire TV Launcher

```bash
cd launcher
./gradlew assembleRelease
adb connect <TV_IP>:5555
adb install -r app/build/outputs/apk/release/app-release.apk
```

Push the recommended runtime config and grant `WRITE_SECURE_SETTINGS` (allows `ServiceRepair` to keep the remote key service alive across reboots):

```bash
adb shell mkdir -p /sdcard/Android/data/com.dkg.tvlauncher/files
adb push config/launcher-config.json /sdcard/Android/data/com.dkg.tvlauncher/files/config.json
adb shell pm grant com.dkg.tvlauncher android.permission.WRITE_SECURE_SETTINGS
adb shell settings put secure enabled_accessibility_services com.dkg.tvlauncher/.InputKeyService
adb shell settings put secure accessibility_enabled 1
```

### 2. Pack GhostLock Payloads

Generate Unix-LF `.tar` archives in `scripts/ghostlock/out/`:

```powershell
# Windows (PowerShell)
.\scripts\pack-payloads.ps1
```

```bash
# Linux / macOS / Git Bash
./scripts/pack-payloads.sh
```

### 3. Disarm OOBE & Block OTA (Temp-Root, Once)

Run `scripts/ghostlock/out/01-disarm-oobe.tar` via GhostLock:

```powershell
$env:ANDROID_SERIAL = '<TV_IP>:5555'
.\root.ps1 <path-to-repo>\scripts\ghostlock\out\01-disarm-oobe.tar 10
```

*(If you don't have temp-root yet and are stuck in an OOBE loop, run `./scripts/oobe-watchdog.sh <TV_IP>:5555` as a temporary no-root workaround.)*

### 4. Make Fire TV Launcher Permanent HOME (Temp-Root, Once)

Run `scripts/ghostlock/out/02-set-home.tar` via GhostLock. This disables `com.amazon.firehomestarter` and `com.amazon.tv.launcher/.ui.HomeActivity_vNext` while keeping `com.amazon.tv.launcher` + `SettingsActivity` enabled, and pins `com.dkg.tvlauncher/.MainActivity` as HOME.

### 5. Debloat Unprotected Packages (ADB Shell, No Root)

```bash
./scripts/debloat-shell.sh <TV_IP>:5555
```

### 6. Freeze Protected Telemetry & Optimize RAM (Temp-Root, Once)

Run via GhostLock:
1. `scripts/ghostlock/out/03-freeze-telemetry.tar` — disables protected telemetry, crash/log uploaders, and account-only Amazon apps.
2. `scripts/ghostlock/out/04-ram-optimize.tar` — disables persistent Amazon bloat (`tcomm`, `imp`, `whad`), protected cloud/cast services (`whisperlink`, `arcus.proxy`, `diode`, `sync.service`), WebView telemetry (`AWVMetricsService`), and 16 background services/receivers on `com.amazon.tv.launcher`.

### 7. Optional: Remap the 4 Branded Remote App Buttons (Temp-Root, Once)

For the Fire TV BLE Penny Remote (`Vendor_0171_Product_041e_Version_0038`), run `scripts/ghostlock/out/05-remap-buttons.tar` via GhostLock and reboot. This writes `/data/system/devices/keylayout/Vendor_0171_Product_041e_Version_0038.kl`, mapping scan codes `744`–`747` to `F1`–`F4` so `FireTVKeyPolicyManager` stops intercepting them. Then open **Launcher settings → Remote buttons** (or `adb shell am start -n com.dkg.tvlauncher/.RemoteButtonsActivity`) to configure Tap & Hold actions.

---

## Verification Checklist

```bash
adb shell cmd package resolve-activity --brief -a android.intent.action.MAIN -c android.intent.category.HOME
# Expected: com.dkg.tvlauncher/.MainActivity

adb shell dumpsys package com.amazon.tv.oobe | grep enabled=              # enabled=3
adb shell dumpsys package com.amazon.firehomestarter | grep enabled=      # enabled=3
adb shell dumpsys package com.amazon.device.messaging | grep enabled=     # enabled=1 (MUST stay enabled!)
adb shell settings get global com.amazon.tv.oobe.RESTRICT_REMOTE_BUTTONS  # 0
```

To verify Fire TV Settings still opens cleanly:
```bash
adb shell am start -n com.amazon.tv.launcher/com.amazon.tv.launcher.ui.MainSettingsActivity
```

---

## Critical Lessons Learned

- **NEVER disable `com.amazon.device.messaging` (ADM):** `com.amazon.tv.launcher/.ui.MainSettingsActivity` crashes on startup with `CloudMessagingServiceException` if ADM is disabled, breaking Fire TV's main Settings menu.
- **`pm enable <pkg>` resets component overrides:** Always enable `com.amazon.tv.launcher` *before* disabling `HomeActivity_vNext` or its background components, never after.
- **Installing any HOME app clears the preferred HOME:** After reinstalling `com.dkg.tvlauncher`, re-pin it with:
  ```bash
  adb shell cmd package set-home-activity --user 0 com.dkg.tvlauncher/.MainActivity
  ```
- **`com.amazon.vizzini` reverts at boot:** Fire OS automatically resets `com.amazon.vizzini` to `enabled=1` on reboot regardless of `pm disable`.
- **Reversibility:** Every step can be undone via `scripts/revert-shell.sh`, `revert-ram-optimize.sh`, and `revert-remap-buttons.sh`.

---

## Credits & License

- **Fire TV Launcher** is based on [CleanYourTV](https://github.com/Gathin23/cleanyourtv) by Gathin (MIT License).
- **GhostLock 4.14** temp-root by [R0rt1z2/GhostLock](https://github.com/R0rt1z2/GhostLock).
- Licensed under the [MIT License](LICENSE).
