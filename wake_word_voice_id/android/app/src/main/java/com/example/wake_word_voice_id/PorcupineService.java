package com.example.wake_word_voice_id;

import android.app.Notification;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.app.Service;
import android.content.Intent;
import android.media.AudioFormat;
import android.media.AudioRecord;
import android.media.MediaRecorder;
import android.os.Build;
import android.os.IBinder;
import androidx.annotation.Nullable;
import androidx.core.app.NotificationCompat;
import ai.picovoice.porcupine.PorcupineManager;
import ai.picovoice.porcupine.PorcupineException;
import ai.picovoice.eagle.*;

public class PorcupineService extends Service {
    private static final String CHANNEL_ID = "WakeWordChannel";
    private static final int NOTIFICATION_ID = 1;
    private static final String ACCESS_KEY = "acaklMqZ8HYXIatuuJRKKYj4p07vzsefUnJxzlRpX20qJDqF+KUv4w==";
    private PorcupineManager porcupineManager;
    private Eagle eagle;
    private AudioRecord audioRecord;
    private boolean isRunning = false;
    private static final int SAMPLE_RATE = 16000;
    private static final int CHANNELS = AudioFormat.CHANNEL_IN_MONO;
    private static final int ENCODING = AudioFormat.ENCODING_PCM_16BIT;
    private static final int BUFFER_SIZE = AudioRecord.getMinBufferSize(SAMPLE_RATE, CHANNELS, ENCODING);
    private static final int FRAME_LENGTH = 512;
    private static final int CIRCULAR_BUFFER_SECONDS = 3; ٍ
    private static final int CIRCULAR_BUFFER_SIZE = SAMPLE_RATE * CIRCULAR_BUFFER_SECONDS;
    private short[] circularBuffer = new short[CIRCULAR_BUFFER_SIZE];
    private int circularBufferIndex = 0;

    @Override
    public void onCreate() {
        super.onCreate();
        createNotificationChannel();

        byte[] profileBytes = MainActivity.loadProfile(getApplicationContext()); // تعديل هنا
        if (profileBytes != null) {
            try {
                EagleProfile profile = new EagleProfile(profileBytes);
                eagle = new Eagle.Builder()
                        .setAccessKey(ACCESS_KEY)
                        .setSpeakerProfiles(new EagleProfile[]{profile})
                        .build(getApplicationContext());
            } catch (EagleException e) {
                stopSelf();
            }
        }

        try {
            porcupineManager = new PorcupineManager.Builder()
                    .setAccessKey(ACCESS_KEY)
                    .setKeywordPath("nabd.ppn")
                    .setSensitivity(0.7f)
                    .build(getApplicationContext(), keywordIndex -> {
                        // تم اكتشاف الكلمة المفتاحية "Hi Abood"
                        if (keywordIndex >= 0) {
                            // استخراج المقطع الصوتي الكامل (آخر 5 ثوانٍ)
                            short[] fullAudio;
                            synchronized (circularBuffer) {
                                fullAudio = new short[CIRCULAR_BUFFER_SIZE];
                                for (int i = 0; i < CIRCULAR_BUFFER_SIZE; i++) {
                                    int index = (circularBufferIndex - CIRCULAR_BUFFER_SIZE + i + CIRCULAR_BUFFER_SIZE) % CIRCULAR_BUFFER_SIZE;
                                    fullAudio[i] = circularBuffer[index];
                                }
                            }

                            // التحقق من الصوت باستخدام Eagle
                            if (eagle != null) {
                                try {
                                    boolean voiceMatched = false;
                                    float[] scores;
                                    for (int i = 0; i < fullAudio.length - FRAME_LENGTH; i += FRAME_LENGTH) {
                                        short[] chunk = new short[FRAME_LENGTH];
                                        System.arraycopy(fullAudio, i, chunk, 0, FRAME_LENGTH);
                                        scores = eagle.process(chunk);
                                        if (scores.length > 0 && scores[0] > 0.7) {
                                            voiceMatched = true;
                                            break;
                                        }
                                    }

                                    if (voiceMatched) {
                                        openApp();
                                    }
                                } catch (EagleException e) {
                                    // تجاهل الأخطاء واستمر
                                }
                            }
                        }
                    });
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
                audioRecord = new AudioRecord(MediaRecorder.AudioSource.MIC, SAMPLE_RATE, CHANNELS, ENCODING, BUFFER_SIZE);
                audioRecord.startRecording();
                isRunning = true;

                // بدء تشغيل PorcupineManager
                porcupineManager.start();

                new Thread(() -> {
                    short[] frameBuffer = new short[FRAME_LENGTH];

                    while (isRunning) {
                        int numRead = audioRecord.read(frameBuffer, 0, frameBuffer.length);
                        if (numRead <= 0) continue;

                        // تخزين البيانات في المخزن الدائري
                        synchronized (circularBuffer) {
                            for (int i = 0; i < numRead; i++) {
                                circularBuffer[circularBufferIndex] = frameBuffer[i];
                                circularBufferIndex = (circularBufferIndex + 1) % CIRCULAR_BUFFER_SIZE;
                            }
                        }
                    }
                }).start();
            } else {
                stopSelf();
            }
        } catch (Exception e) {
            stopSelf();
        }

        return START_STICKY;
    }

    private void openApp() {
        Intent launchIntent = new Intent(this, MainActivity.class);
        launchIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK | Intent.FLAG_ACTIVITY_CLEAR_TOP | Intent.FLAG_ACTIVITY_SINGLE_TOP);
        startActivity(launchIntent);
        stopSelf();
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
        isRunning = false;
        if (audioRecord != null) {
            audioRecord.stop();
            audioRecord.release();
            audioRecord = null;
        }
        if (porcupineManager != null) {
            try {
                porcupineManager.stop();
                porcupineManager.delete();
            } catch (PorcupineException e) {
                // تجاهل الأخطاء عند الإغلاق
            }
        }
        if (eagle != null) {
            eagle.delete();
        }
        super.onDestroy();
    }

    @Nullable
    @Override
    public IBinder onBind(Intent intent) {
        return null;
    }
}