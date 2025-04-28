package com.example.sos_plugin;

import android.content.Context;
import android.hardware.Sensor;
import android.hardware.SensorEvent;
import android.hardware.SensorEventListener;
import android.hardware.SensorManager;
import android.util.Log;

import java.util.ArrayList;
import java.util.List;

import io.flutter.plugin.common.EventChannel;

public class MotionChecker {
    private final Context context;
    private final SensorManager sensorManager;
    private static final String TAG = "MotionChecker";

    public MotionChecker(Context context) {
        this.context = context;
        this.sensorManager = (SensorManager) context.getSystemService(Context.SENSOR_SERVICE);
    }

    public EventChannel.StreamHandler getMotionlessStreamHandler() {
        return new EventChannel.StreamHandler() {
            private SensorEventListener sensorListener;
            private EventChannel.EventSink events;
            private long motionlessStartTime = 0;
            private boolean isMotionless = false;
            private List<Float> accelerationHistory = new ArrayList<>();
            private static final int HISTORY_SIZE = 20; // عدد القراءات (حوالي 2 ثانية إذا كل قراءة 100ms)
            private static final float STD_DEV_THRESHOLD = 0.05f; // عتبة الانحراف المعياري
            private static final float ACCELERATION_THRESHOLD = 0.5f; // عتبة التغير الكلي

            @Override
            public void onListen(Object arguments, EventChannel.EventSink events) {
                this.events = events;
                Sensor accelerometer = sensorManager.getDefaultSensor(Sensor.TYPE_ACCELEROMETER);

                sensorListener = new SensorEventListener() {
                    @Override
                    public void onSensorChanged(SensorEvent event) {
                        float x = event.values[0];
                        float y = event.values[1];
                        float z = event.values[2];
                        float acceleration = (float) Math.sqrt(x * x + y * y + z * z);
                        long currentTime = System.currentTimeMillis();

                        // أضف قيمة التسارع للتاريخ
                        accelerationHistory.add(acceleration);
                        if (accelerationHistory.size() > HISTORY_SIZE) {
                            accelerationHistory.remove(0); // احتفظ بحجم ثابت
                        }

                        // احسب الانحراف المعياري للتسارع
                        float stdDev = calculateStandardDeviation(accelerationHistory);
                        Log.d(TAG, "Acceleration: " + acceleration + ", StdDev: " + stdDev);

                        // احسب التغير الكلي (بين أول وآخر قيمة في التاريخ)
                        float totalChange = 0;
                        if (accelerationHistory.size() >= 2) {
                            totalChange = Math.abs(accelerationHistory.get(accelerationHistory.size() - 1) - accelerationHistory.get(0));
                        }

                        if (stdDev < STD_DEV_THRESHOLD && totalChange < ACCELERATION_THRESHOLD) {
                            if (motionlessStartTime == 0) {
                                motionlessStartTime = currentTime;
                                Log.d(TAG, "Started counting motionless time");
                            }
                            if (currentTime - motionlessStartTime >= 8000) { // 8 ثواني
                                if (!isMotionless) {
                                    isMotionless = true;
                                    Log.d(TAG, "Motionless for 8 seconds, sending true");
                                    events.success(true);
                                }
                            } else {
                                if (!isMotionless) {
                                    events.success(false);
                                }
                            }
                        } else {
                            if (motionlessStartTime != 0) {
                                Log.d(TAG, "Device moved, resetting timer");
                            }
                            motionlessStartTime = 0;
                            if (isMotionless) {
                                isMotionless = false;
                                Log.d(TAG, "Device moved after being motionless, sending false");
                                events.success(false);
                            } else {
                                events.success(false);
                            }
                        }
                    }

                    @Override
                    public void onAccuracyChanged(Sensor sensor, int accuracy) {}
                };

                sensorManager.registerListener(sensorListener, accelerometer, SensorManager.SENSOR_DELAY_NORMAL);
            }

            @Override
            public void onCancel(Object arguments) {
                sensorManager.unregisterListener(sensorListener);
                events = null;
                motionlessStartTime = 0;
                isMotionless = false;
                accelerationHistory.clear();
            }

            // دالة لحساب الانحراف المعياري
            private float calculateStandardDeviation(List<Float> values) {
                if (values.isEmpty()) return 0;

                // احسب المتوسط
                float sum = 0;
                for (Float value : values) {
                    sum += value;
                }
                float mean = sum / values.size();

                // احسب مجموع مربعات الفروق عن المتوسط
                float sumOfSquaredDiffs = 0;
                for (Float value : values) {
                    float diff = value - mean;
                    sumOfSquaredDiffs += diff * diff;
                }

                // الانحراف المعياري = الجذر التربيعي للتباين
                return (float) Math.sqrt(sumOfSquaredDiffs / values.size());
            }
        };
    }

    public EventChannel.StreamHandler getFallStreamHandler() {
        return new EventChannel.StreamHandler() {
            private SensorEventListener sensorListener;
            private EventChannel.EventSink events;

            @Override
            public void onListen(Object arguments, EventChannel.EventSink events) {
                this.events = events;
                Sensor accelerometer = sensorManager.getDefaultSensor(Sensor.TYPE_ACCELEROMETER);
                final float[] lastAcceleration = {0};
                final boolean[] fallDetected = {false};

                sensorListener = new SensorEventListener() {
                    @Override
                    public void onSensorChanged(SensorEvent event) {
                        float x = event.values[0];
                        float y = event.values[1];
                        float z = event.values[2];
                        float acceleration = (float) Math.sqrt(x * x + y * y + z * z);

                        if (lastAcceleration[0] > 0 && Math.abs(acceleration - lastAcceleration[0]) > 5) {
                            if (!fallDetected[0]) {
                                fallDetected[0] = true;
                                events.success(true);
                            }
                        } else {
                            if (!fallDetected[0]) {
                                events.success(false);
                            }
                        }

                        lastAcceleration[0] = acceleration;
                    }

                    @Override
                    public void onAccuracyChanged(Sensor sensor, int accuracy) {}
                };

                sensorManager.registerListener(sensorListener, accelerometer, SensorManager.SENSOR_DELAY_NORMAL);
            }

            @Override
            public void onCancel(Object arguments) {
                sensorManager.unregisterListener(sensorListener);
                events = null;
            }
        };
    }
}