package com.example.mfcc_voiceid;

import androidx.annotation.NonNull;
import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.embedding.engine.plugins.FlutterPlugin;

public class MainActivity extends FlutterActivity {
    private static final String CHANNEL = "audio_processor";

    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);
        BinaryMessenger binaryMessenger = flutterEngine.getDartExecutor().getBinaryMessenger();
        new CustomAudioProcessor().onAttachedToEngine(
                new FlutterPlugin.FlutterPluginBinding(
                        getApplicationContext(),
                        flutterEngine,
                        binaryMessenger,
                        flutterEngine.getRenderer(),
                        flutterEngine.getPlatformViewsController().getRegistry(),
                        null,
                        null
                )
        );
    }
}