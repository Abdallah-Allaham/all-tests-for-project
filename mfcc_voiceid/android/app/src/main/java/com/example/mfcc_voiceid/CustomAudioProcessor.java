package com.example.mfcc_voiceid;

import androidx.annotation.NonNull;
import be.tarsos.dsp.AudioDispatcher;
import be.tarsos.dsp.AudioEvent;
import be.tarsos.dsp.AudioProcessor;
import be.tarsos.dsp.io.TarsosDSPAudioFormat;
import be.tarsos.dsp.io.UniversalAudioInputStream;
import be.tarsos.dsp.mfcc.MFCC;
import java.util.ArrayList;
import java.util.HashMap;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.nio.channels.FileChannel;
import android.util.Log;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;

public class CustomAudioProcessor implements FlutterPlugin, MethodCallHandler {
    private static final String CHANNEL = "audio_processor";
    private static final String TAG = "CustomAudioProcessor";
    private MethodChannel channel;
    private int totalFrames = 0;

    @Override
    public void onAttachedToEngine(@NonNull FlutterPluginBinding binding) {
        channel = new MethodChannel(binding.getBinaryMessenger(), CHANNEL);
        channel.setMethodCallHandler(this);
    }

    @Override
    public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
        channel.setMethodCallHandler(null);
    }

    @Override
    public void onMethodCall(@NonNull MethodCall call, @NonNull Result result) {
        if (call.method.equals("extractFeatures")) {
            String filePath = call.argument("filePath");
            try {
                HashMap<String, Object> resultData = extractFeaturesFromFile(filePath);
                result.success(resultData);
            } catch (Exception e) {
                result.error("FEATURES_ERROR", e.getMessage(), null);
            }
        } else {
            result.notImplemented();
        }
    }

    private HashMap<String, Object> extractFeaturesFromFile(String filePath) throws Exception {
        java.io.File audioFile = new java.io.File(filePath);
        TarsosDSPAudioFormat audioFormat = new TarsosDSPAudioFormat(44100, 16, 1, true, false);
        UniversalAudioInputStream audioStream = new UniversalAudioInputStream(
                new java.io.FileInputStream(audioFile), audioFormat);

        AudioDispatcher dispatcher = new AudioDispatcher(audioStream, 1024, 512);

        final ArrayList<Float> processedSamples = new ArrayList<>();
        final ArrayList<float[]> allFrames = new ArrayList<>();
        totalFrames = 0;
        MFCC mfcc = new MFCC(1024, 44100, 20, 20, 100, 4000);
        dispatcher.addAudioProcessor(mfcc);

        dispatcher.addAudioProcessor(new AudioProcessor() {
            @Override
            public boolean process(AudioEvent audioEvent) {
                totalFrames++;
                float[] buffer = audioEvent.getFloatBuffer();

                // حساب الطاقة (RMS) للإطار
                double sumOfSquares = 0.0;
                for (float sample : buffer) {
                    sumOfSquares += sample * sample;
                }
                float energy = (float) Math.sqrt(sumOfSquares / buffer.length);

                // عتبة الطاقة لتحديد الضوضاء والصمت
                float noiseThreshold = 0.02f;
                if (energy > noiseThreshold) {
                    for (float sample : buffer) {
                        processedSamples.add(sample);
                    }

                    float[] currentMFCC = mfcc.getMFCC();
                    float[] frameMFCC = new float[19];
                    System.arraycopy(currentMFCC, 1, frameMFCC, 0, 19);
                    allFrames.add(frameMFCC);
                }

                return true;
            }

            @Override
            public void processingFinished() {}
        });

        dispatcher.run();
        audioStream.close();

        // Log العينات قبل التطبيع
        StringBuilder samplesLog = new StringBuilder("First 100 samples before normalization: ");
        for (int i = 0; i < Math.min(100, processedSamples.size()); i++) {
            samplesLog.append(String.format("%.4f", processedSamples.get(i))).append(", ");
        }
        Log.d(TAG, samplesLog.toString());

        // التطبيع (Normalization) بناءً على أعلى قيمة (maxAmplitude)
        float maxAmplitude = 0.0f;
        for (float sample : processedSamples) {
            maxAmplitude = Math.max(maxAmplitude, Math.abs(sample));
        }
        if (maxAmplitude > 0) {
            for (int i = 0; i < processedSamples.size(); i++) {
                processedSamples.set(i, processedSamples.get(i) / maxAmplitude);
            }
        }

        // Log العينات بعد التطبيع
        samplesLog = new StringBuilder("First 100 samples after normalization: ");
        for (int i = 0; i < Math.min(100, processedSamples.size()); i++) {
            samplesLog.append(String.format("%.4f", processedSamples.get(i))).append(", ");
        }
        Log.d(TAG, samplesLog.toString());

        // إنشاء HashMap لتخزين النتيجة
        HashMap<String, Object> resultMap = new HashMap<>();

        if (allFrames.isEmpty()) {
            float[] silentFeatures = new float[19];
            silentFeatures[18] = -1.0f;
            resultMap.put("features", silentFeatures);
            resultMap.put("processedFilePath", "");
            return resultMap;
        }

        // نسخ الملف الأصلي بدل كتابة ملف WAV يدوي
        String processedFilePath = copyOriginalFile(filePath);

        // حساب متوسط الـ MFCC
        float[] averageMFCC = new float[19];
        for (float[] frameMFCC : allFrames) {
            for (int i = 0; i < 19; i++) {
                averageMFCC[i] += frameMFCC[i];
            }
        }
        for (int i = 0; i < averageMFCC.length; i++) {
            averageMFCC[i] /= allFrames.size();
        }

        // Standardization للـ MFCC
        float fixedMean = 0.0f;
        float fixedStdDev = 2.0f;
        for (int i = 0; i < averageMFCC.length; i++) {
            averageMFCC[i] = (averageMFCC[i] - fixedMean) / fixedStdDev;
        }

        ArrayList<Float> featuresList = new ArrayList<>();
        for (float value : averageMFCC) {
            featuresList.add(value);
        }

        resultMap.put("features", featuresList);
        resultMap.put("processedFilePath", processedFilePath);

        return resultMap;
    }

    private String copyOriginalFile(String originalFilePath) throws Exception {
        String processedFilePath = originalFilePath.replace(".wav", "_processed.wav");
        File originalFile = new File(originalFilePath);
        File processedFile = new File(processedFilePath);

        // نسخ الملف الأصلي إلى الملف الجديد
        FileChannel sourceChannel = null;
        FileChannel destChannel = null;
        try {
            sourceChannel = new FileInputStream(originalFile).getChannel();
            destChannel = new FileOutputStream(processedFile).getChannel();
            destChannel.transferFrom(sourceChannel, 0, sourceChannel.size());
        } finally {
            if (sourceChannel != null) {
                sourceChannel.close();
            }
            if (destChannel != null) {
                destChannel.close();
            }
        }

        Log.d(TAG, "Original audio copied to: " + processedFilePath);
        return processedFilePath;
    }
}