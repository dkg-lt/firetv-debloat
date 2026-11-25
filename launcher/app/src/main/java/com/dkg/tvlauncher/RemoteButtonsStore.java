package com.dkg.tvlauncher;

import android.Manifest;
import android.content.ComponentName;
import android.content.ContentResolver;
import android.content.Context;
import android.content.SharedPreferences;
import android.content.pm.PackageManager;
import android.provider.Settings;
import android.view.KeyEvent;

import java.util.ArrayList;
import java.util.List;

/**
 * Persistent on-TV storage for the 4 remappable Fire TV app buttons (mapped to F1-F4 by the
 * KeyLayout override). Each button supports both a short tap and a 500 ms long press ("hold:").
 */
final class RemoteButtonsStore {
    private static final String PREFS = "remote_buttons";

    static final int COUNT = 4;

    static final int[] KEYCODES = {
            KeyEvent.KEYCODE_F1,
            KeyEvent.KEYCODE_F2,
            KeyEvent.KEYCODE_F3,
            KeyEvent.KEYCODE_F4
    };

    static final String[] KEYCODE_NAMES = {
            "KEYCODE_F1",
            "KEYCODE_F2",
            "KEYCODE_F3",
            "KEYCODE_F4"
    };

    static final int[] SCANCODES = {744, 745, 746, 747};

    static final String[][] BUILTIN_ACTIONS = {
            {"", "None (disabled)"},
            {"home", "Action: Home"},
            {"back", "Action: Back"},
            {"recents", "Action: Recents / App Switcher"},
            {"settings", "Action: TV Settings"},
            {"wifi", "Action: Wi-Fi / Network"},
            {"inputs", "Action: Inputs Menu"},
            {"screensaver", "Action: Screensaver"},
            {"sleep", "Action: Sleep / Standby"},
            {"mute", "Action: Toggle Mute"},
            {"library", "Action: App Library"},
            {"com.dkg.tvlauncher/.LauncherSettingsActivity", "Action: Launcher Settings"},
            {"com.dkg.tvlauncher/.RemoteButtonsActivity", "Action: Remote Buttons"},
            {"ignore", "Action: Ignore (swallow key)"}
    };

    private RemoteButtonsStore() { }

    static SharedPreferences prefs(Context ctx) {
        return ctx.getSharedPreferences(PREFS, Context.MODE_PRIVATE);
    }

    static String getTap(Context ctx, int slot) {
        return prefs(ctx).getString("tap_" + slot, "");
    }

    static String getHold(Context ctx, int slot) {
        return prefs(ctx).getString("hold_" + slot, "");
    }

    static void setTap(Context ctx, int slot, String target) {
        SharedPreferences.Editor e = prefs(ctx).edit();
        if (target == null || target.isEmpty()) e.remove("tap_" + slot);
        else e.putString("tap_" + slot, target);
        e.apply();
    }

    static void setHold(Context ctx, int slot, String target) {
        SharedPreferences.Editor e = prefs(ctx).edit();
        if (target == null || target.isEmpty()) e.remove("hold_" + slot);
        else e.putString("hold_" + slot, target);
        e.apply();
    }

    static void resetAll(Context ctx) {
        prefs(ctx).edit().clear().apply();
    }

    /** Returns RemoteKeys app_keys entries for all configured tap and hold slots. */
    static List<String> toAppKeyEntries(Context ctx) {
        SharedPreferences p = prefs(ctx);
        List<String> out = new ArrayList<>();
        for (int i = 0; i < COUNT; i++) {
            String tap = p.getString("tap_" + i, "");
            if (tap != null && !tap.isEmpty()) {
                out.add(KEYCODE_NAMES[i] + ":" + tap);
            }
            String hold = p.getString("hold_" + i, "");
            if (hold != null && !hold.isEmpty()) {
                out.add("hold:" + KEYCODE_NAMES[i] + ":" + hold);
            }
        }
        return out;
    }

    static int slotForKey(int keyCode, int scanCode) {
        for (int i = 0; i < COUNT; i++) {
            if (keyCode == KEYCODES[i] || (scanCode > 0 && scanCode == SCANCODES[i])) return i;
        }
        return -1;
    }

    static String describeTarget(Context ctx, String target) {
        if (target == null || target.isEmpty()) return "None";
        for (String[] action : BUILTIN_ACTIONS) {
            if (action[0].equals(target)) return action[1];
        }
        try {
            PackageManager pm = ctx.getPackageManager();
            String pkg = target.contains("/") ? target.substring(0, target.indexOf('/')) : target;
            return pm.getApplicationLabel(pm.getApplicationInfo(pkg, 0)).toString();
        } catch (PackageManager.NameNotFoundException e) {
            return target;
        }
    }

    static boolean isServiceRunning() {
        return InputKeyService.running != null;
    }

    static boolean canToggleService(Context ctx) {
        return ctx.checkSelfPermission(Manifest.permission.WRITE_SECURE_SETTINGS)
                == PackageManager.PERMISSION_GRANTED;
    }

    static boolean setServiceEnabled(Context ctx, boolean enable) {
        if (!canToggleService(ctx)) return false;
        try {
            ContentResolver cr = ctx.getContentResolver();
            ComponentName self = new ComponentName(ctx.getPackageName(), InputKeyService.class.getName());
            String list = Settings.Secure.getString(cr, Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES);
            List<ComponentName> current = new ArrayList<>();
            if (list != null) {
                for (String entry : list.split(":")) {
                    ComponentName cn = ComponentName.unflattenFromString(entry);
                    if (cn != null && !cn.equals(self)) current.add(cn);
                }
            }
            if (enable) current.add(self);
            StringBuilder sb = new StringBuilder();
            for (ComponentName cn : current) {
                if (sb.length() > 0) sb.append(':');
                sb.append(cn.flattenToShortString());
            }
            Settings.Secure.putString(cr, Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES, sb.toString());
            Settings.Secure.putInt(cr, Settings.Secure.ACCESSIBILITY_ENABLED, current.isEmpty() ? 0 : 1);
            return true;
        } catch (RuntimeException e) {
            return false;
        }
    }
}
