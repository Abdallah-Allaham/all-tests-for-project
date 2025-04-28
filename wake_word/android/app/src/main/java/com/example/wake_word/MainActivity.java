package com.example.wake_word;

import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodChannel;
import android.content.Intent;

import android.os.PowerManager;
import android.provider.Settings;
import android.content.Intent;
import android.net.Uri;
import android.os.Build;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodChannel;

public class MainActivity extends FlutterActivity {
    private static final String CHANNEL = "com.example.wake_word/foreground";

    @Override
    public void configureFlutterEngine(FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);
        new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), "battery_optimizations")
                .setMethodCallHandler((call, result) -> {
                    if (call.method.equals("requestIgnoreBatteryOptimizations")) {
                        PowerManager pm = (PowerManager) getSystemService(POWER_SERVICE);
                        String packageName = getPackageName();
                        if (pm != null && !pm.isIgnoringBatteryOptimizations(packageName)) {
                            Intent intent = new Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS);
                            intent.setData(Uri.parse("package:" + packageName));
                            startActivity(intent);
                        }
                        result.success(null);
                    } else {
                        result.notImplemented();
                    }
                });
    }
}