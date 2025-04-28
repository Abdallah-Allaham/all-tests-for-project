import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  static const platform = MethodChannel('com.example.wake_word/foreground');

  static const platform2 = MethodChannel('battery_optimizations');

  void requestIgnoreBatteryOptimization() async {
    try {
      await platform2.invokeMethod('requestIgnoreBatteryOptimizations');
    } catch (e) {
      print("Failed to request ignore battery optimization: $e");
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      stopService();
    } else if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
      startService();
    }
  }

  Future<void> startService() async {
    try {
      await platform.invokeMethod('startService');
    } catch (e) {
      print("Error starting service: $e");
    }
  }

  Future<void> stopService() async {
    try {
      await platform.invokeMethod('stopService');
    } catch (e) {
      print("Error stopping service: $e");
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: Text('Wake Word App')),
        body: Center(child: Text('قل "نبض" لفتح التطبيق!')),
      ),
    );
  }
}
