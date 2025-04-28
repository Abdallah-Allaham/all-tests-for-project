package com.example.sos_plugin;

import androidx.annotation.NonNull;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;

public class SosPlugin implements FlutterPlugin, MethodCallHandler {
    private MethodChannel channel;
    private InternetChecker internetChecker;
    private MotionChecker motionChecker;
    private LocationChecker locationChecker;

    @Override
    public void onAttachedToEngine(@NonNull FlutterPluginBinding flutterPluginBinding) {
        channel = new MethodChannel(flutterPluginBinding.getBinaryMessenger(), "sos_plugin");
        channel.setMethodCallHandler(this);

        internetChecker = new InternetChecker(flutterPluginBinding.getApplicationContext());
        motionChecker = new MotionChecker(flutterPluginBinding.getApplicationContext());
        locationChecker = new LocationChecker(flutterPluginBinding.getApplicationContext());

        // Setup Event Channels
        new EventChannel(flutterPluginBinding.getBinaryMessenger(), "sos_plugin/internet")
                .setStreamHandler(internetChecker);
        new EventChannel(flutterPluginBinding.getBinaryMessenger(), "sos_plugin/motionless")
                .setStreamHandler(motionChecker.getMotionlessStreamHandler());
        new EventChannel(flutterPluginBinding.getBinaryMessenger(), "sos_plugin/fall")
                .setStreamHandler(motionChecker.getFallStreamHandler());
        new EventChannel(flutterPluginBinding.getBinaryMessenger(), "sos_plugin/location")
                .setStreamHandler(locationChecker);
    }

    @Override
    public void onMethodCall(@NonNull MethodCall call, @NonNull Result result) {
        if (call.method.equals("setHomeLocation")) {
            double latitude = call.argument("latitude");
            double longitude = call.argument("longitude");
            locationChecker.setHomeLocation(latitude, longitude);
            result.success("Home location set");
        } else {
            result.notImplemented();
        }
    }

    @Override
    public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
        channel.setMethodCallHandler(null);
    }
}