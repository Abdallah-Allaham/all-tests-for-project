package com.example.wake_word;

import android.app.Notification;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.app.Service;
import android.content.Intent;
import android.os.Build;
import android.os.IBinder;
import android.util.Log;
import androidx.core.app.NotificationCompat;
import ai.picovoice.porcupine.PorcupineManager;
import ai.picovoice.porcupine.PorcupineException;
import ai.picovoice.porcupine.PorcupineManagerCallback;
import android.accessibilityservice.AccessibilityServiceInfo;
import android.view.accessibility.AccessibilityManager;


public class PorcupainService extends Service {
    private static final String TAG = "PorcupainService";
    private static final String CHANNEL_ID = "WakeWordChannel";
    private static final int NOTIFICATION_ID = 1;
    private PorcupineManager porcupineManager;
    private boolean isRunning = false;
    private int wakeWordCount = 0;
    private NotificationManager notificationManager;

    String apiKey="acaklMqZ8HYXIatuuJRKKYj4p07vzsefUnJxzlRpX20qJDqF+KUv4w==";

    @Override
    public void onCreate() {
        super.onCreate();
        Log.d(TAG, "Service Created");
        notificationManager = (NotificationManager) getSystemService(NOTIFICATION_SERVICE);
        createNotificationChannel();

        try {
            porcupineManager = new PorcupineManager.Builder()
                    .setAccessKey(apiKey) // استبدل بمفتاحك
                    .setKeywordPath("nabd.ppn") // الملف في assets
                    .setSensitivity(0.7f)
                    .build(this, new PorcupineManagerCallback() {
                        @Override
                        public void invoke(int keywordIndex) {
                            if (keywordIndex == 0) {
                                wakeWordCount++;
                                Log.d(TAG, "Keyword 'نبض' detected! Count: " + wakeWordCount);
                                updateNotification();
                                openApp();
                                // تم إزالة stopSelf() هنا لعدم تدمير الخدمة
                            }
                        }
                    });
            Log.d(TAG, "PorcupineManager initialized successfully");
        } catch (PorcupineException e) {
            Log.e(TAG, "Failed to initialize PorcupineManager: " + e.getMessage());
        }
    }

    @Override
    public int onStartCommand(Intent intent, int flags, int startId) {
        if (!isRunning) {
            isRunning = true;
            Notification notification = createNotification();
            startForeground(NOTIFICATION_ID, notification);
            Log.d(TAG, "Foreground service started with notification");
            startListening();
        }
        return START_STICKY; // هذه الطريقة تضمن استمرار الخدمة حتى في حالة توقف الـ Activity
    }

    private void startListening() {
        try {
            porcupineManager.start();
            Log.d(TAG, "PorcupineManager started listening");
        } catch (PorcupineException e) {
            Log.e(TAG, "Failed to start PorcupineManager: " + e.getMessage());
            stopSelf();
        }
    }

    private void openApp() {
        Intent launchIntent = getPackageManager().getLaunchIntentForPackage("com.example.wake_word");
        if (launchIntent != null) {
            launchIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK | Intent.FLAG_ACTIVITY_CLEAR_TOP);
            startActivity(launchIntent);
            Log.d(TAG, "App launched successfully");
        } else {
            Log.e(TAG, "Launch intent is null");
        }
    }



    private Notification createNotification() {
        NotificationCompat.Builder builder = new NotificationCompat.Builder(this, CHANNEL_ID)
                .setSmallIcon(android.R.drawable.ic_dialog_info)
                .setContentTitle("Wake Word Service")
                .setContentText("Listening... Detected 'نبض' " + wakeWordCount + " times")
                .setPriority(NotificationCompat.PRIORITY_LOW)
                .setOngoing(true)
                .setPriority(NotificationCompat.PRIORITY_HIGH);
        Notification notification = builder.build();
        Log.d(TAG, "Notification created: Detected 'نبض' " + wakeWordCount + " times");
        return notification;
    }

    private void updateNotification() {
        Notification updatedNotification = createNotification();
        notificationManager.notify(NOTIFICATION_ID, updatedNotification);
        Log.d(TAG, "Notification updated: Detected 'نبض' " + wakeWordCount + " times");
    }

    private void createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            NotificationChannel channel = new NotificationChannel(
                    CHANNEL_ID,
                    "Wake Word Channel",
                    NotificationManager.IMPORTANCE_LOW
            );
            notificationManager.createNotificationChannel(channel);
            Log.d(TAG, "Notification channel created");
        }
    }


    @Override
    public void onDestroy() {
        isRunning = false;
        if (porcupineManager != null) {
            try {
                porcupineManager.stop();
                porcupineManager.delete();
                Log.d(TAG, "PorcupineManager stopped and deleted");
            } catch (PorcupineException e) {
                Log.e(TAG, "Error stopping PorcupineManager: " + e.getMessage());
            }
        }
        super.onDestroy();
        Log.d(TAG, "Service Destroyed");
    }

    @Override
    public IBinder onBind(Intent intent) {
        return null;
    }
}
