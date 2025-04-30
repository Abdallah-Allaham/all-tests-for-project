package com.example.wake_word_voice_id;

import ai.picovoice.eagle.*;
import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodChannel;
import android.Manifest;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.content.Context;
import android.media.AudioFormat;
import android.media.AudioRecord;
import android.media.MediaRecorder;
import androidx.core.app.ActivityCompat;
import java.io.File;
import java.io.FileOutputStream;
import java.io.FileInputStream;
import java.util.HashMap;
import java.util.Map;

public class MainActivity extends FlutterActivity {
    private static final String CHANNEL = "voice_id_app/eagle";
    private static final String ACCESS_KEY = "acaklMqZ8HYXIatuuJRKKYj4p07vzsefUnJxzlRpX20qJDqF+KUv4w==";
    private Eagle eagle;
    private EagleProfiler eagleProfiler;
    private AudioRecord audioRecord;
    private EagleProfile speakerProfile;
    private boolean isRecording = false;
    private static final int SAMPLE_RATE = 16000;
    private static final int CHANNELS = AudioFormat.CHANNEL_IN_MONO;
    private static final int ENCODING = AudioFormat.ENCODING_PCM_16BIT;
    private static final int BUFFER_SIZE = AudioRecord.getMinBufferSize(SAMPLE_RATE, CHANNELS, ENCODING);
    private static final int FRAME_LENGTH = 512;

    @Override
    protected void onCreate(android.os.Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        Intent serviceIntent = new Intent(this, PorcupineService.class);
        stopService(serviceIntent);

        // تحميل ملف الـ Speaker Profile عند بدء التشغيل
        loadSpeakerProfile();
    }

    private void loadSpeakerProfile() {
        byte[] profileBytes = loadProfile(getApplicationContext());
        if (profileBytes != null) {
            try {
                speakerProfile = new EagleProfile(profileBytes);
                eagle = new Eagle.Builder()
                        .setAccessKey(ACCESS_KEY)
                        .setSpeakerProfiles(new EagleProfile[]{speakerProfile})
                        .build(getApplicationContext());
            } catch (EagleException e) {
                // تجاهل الأخطاء، سيتم طلب الـ Enrollment إذا فشل التحميل
                speakerProfile = null;
                eagle = null;
            }
        }
    }

    @Override
    public void configureFlutterEngine(FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);
        new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), CHANNEL)
                .setMethodCallHandler((call, result) -> {
                    switch (call.method) {
                        case "initEagle":
                            initEagle(result);
                            break;
                        case "enrollVoice":
                            enrollVoice(result);
                            break;
                        case "verifyVoice":
                            verifyVoice(result);
                            break;
                        case "stopRecording":
                            stopRecording(result);
                            break;
                        case "isProfileEnrolled":
                            result.success(speakerProfile != null);
                            break;
                        default:
                            result.notImplemented();
                    }
                });
    }

    private void initEagle(MethodChannel.Result result) {
        result.success("Eagle initialization skipped until enrollment");
    }

    private void enrollVoice(MethodChannel.Result result) {
        try {
            if (ActivityCompat.checkSelfPermission(this, Manifest.permission.RECORD_AUDIO) != PackageManager.PERMISSION_GRANTED) {
                ActivityCompat.requestPermissions(this, new String[]{Manifest.permission.RECORD_AUDIO}, 1);
                result.error("PERMISSION_ERROR", "Microphone permission not granted", null);
                return;
            }

            eagleProfiler = new EagleProfiler.Builder()
                    .setAccessKey(ACCESS_KEY)
                    .build(getApplicationContext());

            audioRecord = new AudioRecord(MediaRecorder.AudioSource.MIC, SAMPLE_RATE, CHANNELS, ENCODING, BUFFER_SIZE);
            audioRecord.startRecording();
            isRecording = true;

            new Thread(() -> {
                float percentage = 0;
                long startTime = System.currentTimeMillis();
                long timeoutMillis = 30000;

                int minEnrollSamples = eagleProfiler.getMinEnrollSamples();
                int numFramesPerEnroll = minEnrollSamples / FRAME_LENGTH;

                while (isRecording && percentage < 100 && (System.currentTimeMillis() - startTime) < timeoutMillis) {
                    short[] enrollBuffer = new short[numFramesPerEnroll * FRAME_LENGTH];
                    int totalSamplesRead = 0;

                    for (int i = 0; i < numFramesPerEnroll; i++) {
                        short[] frameBuffer = new short[FRAME_LENGTH];
                        int numRead = audioRecord.read(frameBuffer, 0, frameBuffer.length);
                        if (numRead <= 0) {
                            runOnUiThread(() -> result.error("AUDIO_READ_ERROR", "Failed to read audio data", null));
                            return;
                        }
                        System.arraycopy(frameBuffer, 0, enrollBuffer, i * FRAME_LENGTH, numRead);
                        totalSamplesRead += numRead;
                    }

                    try {
                        EagleProfilerEnrollResult feedbackResult = eagleProfiler.enroll(enrollBuffer);
                        percentage = feedbackResult.getPercentage();
                        final float currentPercentage = percentage;
                        runOnUiThread(() -> {
                            MethodChannel channel = new MethodChannel(
                                    getFlutterEngine().getDartExecutor().getBinaryMessenger(), CHANNEL);
                            Map<String, Object> progressData = new HashMap<>();
                            progressData.put("percentage", currentPercentage);
                            progressData.put("feedback", feedbackResult.getFeedback().name());
                            channel.invokeMethod("updateProgress", progressData);
                        });
                    } catch (EagleException e) {
                        runOnUiThread(() -> result.error("ENROLL_ERROR", e.getMessage(), null));
                        return;
                    }
                }

                if (percentage >= 100) {
                    try {
                        speakerProfile = eagleProfiler.export();
                        eagle = new Eagle.Builder()
                                .setAccessKey(ACCESS_KEY)
                                .setSpeakerProfiles(new EagleProfile[]{speakerProfile})
                                .build(getApplicationContext());
                        saveProfile(speakerProfile);
                        runOnUiThread(() -> result.success("تم"));
                    } catch (EagleException e) {
                        runOnUiThread(() -> result.error("EXPORT_ERROR", e.getMessage(), null));
                    }
                } else if ((System.currentTimeMillis() - startTime) >= timeoutMillis) {
                    runOnUiThread(() -> result.error("ENROLL_TIMEOUT", "فشل التسجيل. تأكد من التحدث بوضوح وبصوت عالٍ في بيئة هادئة وحاول مرة أخرى.", null));
                } else {
                    runOnUiThread(() -> result.error("ENROLL_INCOMPLETE", "Could not complete enrollment", null));
                }

                stopRecording(null);
            }).start();
        } catch (Exception e) {
            result.error("ENROLL_INIT_ERROR", e.getMessage(), null);
        }
    }

    private void saveProfile(EagleProfile profile) {
        try {
            File file = new File(getFilesDir(), "speaker_profile.bin");
            FileOutputStream fos = new FileOutputStream(file);
            fos.write(profile.getBytes());
            fos.close();
        } catch (Exception e) {
            // تجاهل الأخطاء
        }
    }

    public static byte[] loadProfile(Context context) {
        try {
            File file = new File(context.getFilesDir(), "speaker_profile.bin");
            if (!file.exists()) return null;
            FileInputStream fis = new FileInputStream(file);
            byte[] data = new byte[(int) file.length()];
            fis.read(data);
            fis.close();
            return data;
        } catch (Exception e) {
            return null;
        }
    }

    private void verifyVoice(MethodChannel.Result result) {
        if (speakerProfile == null || eagle == null) {
            result.error("NO_PROFILE", "No voice profile enrolled. Please enroll a voice first.", null);
            return;
        }

        try {
            if (ActivityCompat.checkSelfPermission(this, Manifest.permission.RECORD_AUDIO) != PackageManager.PERMISSION_GRANTED) {
                ActivityCompat.requestPermissions(this, new String[]{Manifest.permission.RECORD_AUDIO}, 1);
                result.error("PERMISSION_ERROR", "Microphone permission not granted", null);
                return;
            }

            audioRecord = new AudioRecord(MediaRecorder.AudioSource.MIC, SAMPLE_RATE, CHANNELS, ENCODING, BUFFER_SIZE);
            audioRecord.startRecording();
            isRecording = true;

            new Thread(() -> {
                short[] buffer = new short[FRAME_LENGTH];
                float[] scores;

                while (isRecording) {
                    int numRead = audioRecord.read(buffer, 0, buffer.length);
                    try {
                        scores = eagle.process(buffer);
                        if (scores.length > 0 && scores[0] > 0.7) {
                            runOnUiThread(() -> result.success("Voice matched"));
                            stopRecording(null);
                            return;
                        }
                    } catch (EagleException e) {
                        runOnUiThread(() -> result.error("VERIFY_ERROR", e.getMessage(), null));
                        return;
                    }
                }
                runOnUiThread(() -> result.success("Voice not matched"));
            }).start();
        } catch (Exception e) {
            result.error("VERIFY_INIT_ERROR", e.getMessage(), null);
        }
    }

    private void stopRecording(MethodChannel.Result result) {
        isRecording = false;
        if (audioRecord != null) {
            audioRecord.stop();
            audioRecord.release();
            audioRecord = null;
        }
        if (eagleProfiler != null) {
            eagleProfiler.delete();
            eagleProfiler = null;
        }
        if (result != null) {
            result.success("Recording stopped");
        }
    }

    @Override
    protected void onResume() {
        super.onResume();
        Intent serviceIntent = new Intent(this, PorcupineService.class);
        stopService(serviceIntent);
    }

    @Override
    protected void onPause() {
        super.onPause();
        Intent serviceIntent = new Intent(this, PorcupineService.class);
        startService(serviceIntent);
    }

    @Override
    protected void onDestroy() {
        super.onDestroy();
        if (eagle != null) {
            eagle.delete();
        }
    }
}