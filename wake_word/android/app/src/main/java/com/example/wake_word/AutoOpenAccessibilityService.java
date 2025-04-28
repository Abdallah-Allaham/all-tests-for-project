package com.example.wake_word;

import android.accessibilityservice.AccessibilityService;
import android.content.Intent;
import android.util.Log;
import android.view.accessibility.AccessibilityEvent;

public class AutoOpenAccessibilityService extends AccessibilityService {

    @Override
    public void onAccessibilityEvent(AccessibilityEvent event) {
        // لا حاجة للحدث هنا لأننا بنستخدم الخدمة فقط للتشغيل
    }

    @Override
    public void onInterrupt() {
    }

    public void launchAppFromService() {
        Log.d("AccessibilityService", "Trying to launch app from accessibility service");
        Intent launchIntent = getPackageManager().getLaunchIntentForPackage("com.example.wake_word");
        if (launchIntent != null) {
            launchIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK | Intent.FLAG_ACTIVITY_CLEAR_TOP);
            startActivity(launchIntent);
        } else {
            Log.e("AccessibilityService", "Launch intent is null");
        }
    }
}
