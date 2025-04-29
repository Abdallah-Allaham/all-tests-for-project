package com.example.wake_word_voice_id;

import android.app.Notification;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.app.Service;
import android.content.Intent;
import android.os.Build;
import android.os.IBinder;
import androidx.annotation.Nullable;
import androidx.core.app.NotificationCompat;
import ai.picovoice.porcupine.PorcupineManager;
import ai.picovoice.porcupine.PorcupineException;

public class PorcupineService extends Service {
    private static final String CHANNEL_ID = "WakeWordChannel";
    private static final int NOTIFICATION_ID = 1;
    private PorcupineManager porcupineManager;

    private static final String ACCESS_KEY = "acaklMqZ8HYXIatuuJRKKYj4p07vzsefUnJxzlRpX20qJDqF+KUv4w==";

    @Override
    public void onCreate() {
        super.onCreate();
        createNotificationChannel();

        try {
            porcupineManager = new PorcupineManager.Builder()
                    .setAccessKey(ACCESS_KEY)
                    .setKeywordPath("nabd.ppn")
                    .setSensitivity(0.7f)
                    .build(getApplicationContext(), keywordIndex -> openApp());
        } catch (PorcupineException e) {
            stopSelf();
        }
    }

    @Override
    public int onStartCommand(Intent intent, int flags, int startId) {
        Notification notification = new NotificationCompat.Builder(this, CHANNEL_ID)
                .setSmallIcon(android.R.drawable.ic_dialog_info)
                .setContentTitle("Wake Word Service")
                .setContentText("Listening for wake word...")
                .setPriority(NotificationCompat.PRIORITY_LOW)
                .setOngoing(true)
                .build();

        startForeground(NOTIFICATION_ID, notification);

        try {
            if (porcupineManager != null) {
                porcupineManager.start();
            } else {
                stopSelf();
            }
        } catch (PorcupineException e) {
            stopSelf();
        }

        return START_STICKY; // إعادة START_STICKY
    }

    private void openApp() {
        Intent launchIntent = new Intent(this, MainActivity.class);
        launchIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK | Intent.FLAG_ACTIVITY_CLEAR_TOP | Intent.FLAG_ACTIVITY_SINGLE_TOP);
        startActivity(launchIntent);
        stopSelf(); // إيقاف الخدمة بعد فتح التطبيق
    }

    private void createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            NotificationChannel channel = new NotificationChannel(
                    CHANNEL_ID,
                    "Wake Word Channel",
                    NotificationManager.IMPORTANCE_LOW
            );
            NotificationManager manager = getSystemService(NotificationManager.class);
            manager.createNotificationChannel(channel);
        }
    }

    @Override
    public void onDestroy() {
        if (porcupineManager != null) {
            try {
                porcupineManager.stop();
                porcupineManager.delete();
            } catch (PorcupineException e) {
                // تجاهل الأخطاء عند الإغلاق
            }
        }
        super.onDestroy();
    }

    @Nullable
    @Override
    public IBinder onBind(Intent intent) {
        return null;
    }
}