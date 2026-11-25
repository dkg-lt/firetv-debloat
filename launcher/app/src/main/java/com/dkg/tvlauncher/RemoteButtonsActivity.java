package com.dkg.tvlauncher;

import android.app.Activity;
import android.app.AlertDialog;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.content.pm.ResolveInfo;
import android.os.Bundle;
import android.view.KeyEvent;
import android.widget.TextView;
import android.widget.Toast;

import java.util.ArrayList;
import java.util.Collections;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

/**
 * TV-remote-friendly configuration screen for the 4 remappable Fire TV app buttons (F1-F4).
 * Pressing any of the 4 physical buttons while this screen is open highlights that button
 * instead of firing its mapped action, making identification effortless.
 */
public final class RemoteButtonsActivity extends Activity {

    /** While true, InputKeyService lets F1-F4 pass through so this screen can identify them. */
    static volatile boolean capturing = false;

    private static final String[] BUTTON_LABELS = {
            "Button 1 — Prime Video (F1)",
            "Button 2 — Netflix (F2)",
            "Button 3 — Disney+ (F3)",
            "Button 4 — Amazon Music (F4)"
    };

    private TextView serviceStatusRow;
    private TextView identifyBanner;
    private final TextView[] tapRows = new TextView[RemoteButtonsStore.COUNT];
    private final TextView[] holdRows = new TextView[RemoteButtonsStore.COUNT];

    @Override
    protected void attachBaseContext(android.content.Context base) {
        super.attachBaseContext(LauncherLocale.wrap(base));
    }

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_remote_buttons);

        serviceStatusRow = findViewById(R.id.serviceStatusRow);
        identifyBanner = findViewById(R.id.identifyBanner);

        int[] tapIds = {R.id.btn1Tap, R.id.btn2Tap, R.id.btn3Tap, R.id.btn4Tap};
        int[] holdIds = {R.id.btn1Hold, R.id.btn2Hold, R.id.btn3Hold, R.id.btn4Hold};
        for (int i = 0; i < RemoteButtonsStore.COUNT; i++) {
            final int slot = i;
            tapRows[i] = findViewById(tapIds[i]);
            holdRows[i] = findViewById(holdIds[i]);
            tapRows[i].setOnClickListener(v -> showTargetPicker(slot, false));
            holdRows[i].setOnClickListener(v -> showTargetPicker(slot, true));
        }

        serviceStatusRow.setOnClickListener(v -> {
            boolean currentlyRunning = RemoteButtonsStore.isServiceRunning();
            if (!RemoteButtonsStore.canToggleService(this)) {
                Toast.makeText(this, "Grant WRITE_SECURE_SETTINGS via ADB to toggle here", Toast.LENGTH_LONG).show();
                return;
            }
            RemoteButtonsStore.setServiceEnabled(this, !currentlyRunning);
            serviceStatusRow.postDelayed(this::refresh, 500);
        });

        findViewById(R.id.resetButtonsRow).setOnClickListener(v ->
                new AlertDialog.Builder(this)
                        .setTitle(R.string.remote_buttons_reset)
                        .setMessage(R.string.remote_buttons_reset_confirm)
                        .setPositiveButton(android.R.string.ok, (d, w) -> {
                            RemoteButtonsStore.resetAll(this);
                            InputKeyService.reload(this);
                            refresh();
                            Toast.makeText(this, R.string.remote_buttons_reset_done, Toast.LENGTH_SHORT).show();
                        })
                        .setNegativeButton(android.R.string.cancel, null)
                        .show());

        refresh();
        tapRows[0].requestFocus();
    }

    @Override
    protected void onResume() {
        super.onResume();
        capturing = true;
        refresh();
    }

    @Override
    protected void onPause() {
        capturing = false;
        super.onPause();
    }

    @Override
    public boolean dispatchKeyEvent(KeyEvent event) {
        int slot = RemoteButtonsStore.slotForKey(event.getKeyCode(), event.getScanCode());
        if (slot >= 0) {
            if (event.getAction() == KeyEvent.ACTION_DOWN && event.getRepeatCount() == 0) {
                identifyBanner.setText("Detected: " + BUTTON_LABELS[slot]
                        + "  (scan " + event.getScanCode() + ", key " + KeyEvent.keyCodeToString(event.getKeyCode()) + ")");
                tapRows[slot].requestFocus();
            }
            return true;
        }
        return super.dispatchKeyEvent(event);
    }

    private void refresh() {
        boolean running = RemoteButtonsStore.isServiceRunning();
        String state = running ? "Active" : "Off (press OK to enable)";
        serviceStatusRow.setText(getString(R.string.remote_buttons_service_state, state));
        for (int i = 0; i < RemoteButtonsStore.COUNT; i++) {
            String tap = RemoteButtonsStore.describeTarget(this, RemoteButtonsStore.getTap(this, i));
            String hold = RemoteButtonsStore.describeTarget(this, RemoteButtonsStore.getHold(this, i));
            tapRows[i].setText("Tap:  " + tap);
            holdRows[i].setText("Hold (0.5s):  " + hold);
        }
    }

    private void showTargetPicker(int slot, boolean isHold) {
        List<String> labels = new ArrayList<>();
        List<String> targets = new ArrayList<>();

        for (String[] action : RemoteButtonsStore.BUILTIN_ACTIONS) {
            targets.add(action[0]);
            labels.add(action[1]);
        }

        // Append all installed launchable apps (TV Leanback + standard Launcher), deduplicated & sorted.
        PackageManager pm = getPackageManager();
        List<String[]> apps = new ArrayList<>();
        Set<String> seen = new HashSet<>();
        seen.add(getPackageName());
        Intent[] queries = {
                new Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_LEANBACK_LAUNCHER),
                new Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_LAUNCHER)
        };
        for (Intent q : queries) {
            for (ResolveInfo r : pm.queryIntentActivities(q, 0)) {
                String pkg = r.activityInfo.packageName;
                if (seen.add(pkg)) {
                    CharSequence lbl = r.loadLabel(pm);
                    apps.add(new String[]{lbl != null ? lbl.toString() : pkg, pkg});
                }
            }
        }
        Collections.sort(apps, (a, b) -> a[0].compareToIgnoreCase(b[0]));
        for (String[] app : apps) {
            labels.add("App: " + app[0]);
            targets.add(app[1]);
        }

        String current = isHold ? RemoteButtonsStore.getHold(this, slot)
                : RemoteButtonsStore.getTap(this, slot);
        int checked = 0;
        for (int i = 0; i < targets.size(); i++) {
            if (targets.get(i).equals(current)) {
                checked = i;
                break;
            }
        }

        String title = BUTTON_LABELS[slot] + (isHold ? " — Hold" : " — Tap");
        new AlertDialog.Builder(this)
                .setTitle(title)
                .setSingleChoiceItems(labels.toArray(new String[0]), checked, (dialog, which) -> {
                    dialog.dismiss();
                    String chosen = targets.get(which);
                    if (isHold) RemoteButtonsStore.setHold(this, slot, chosen);
                    else RemoteButtonsStore.setTap(this, slot, chosen);
                    InputKeyService.reload(this);
                    refresh();
                })
                .setNegativeButton(android.R.string.cancel, null)
                .show();
    }
}
