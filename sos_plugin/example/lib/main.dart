import 'package:flutter/material.dart';
import 'package:sos_plugin/sos_plugin.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final SosPlugin _sosPlugin = SosPlugin();
  String _internetResult = "Not tested";
  String _motionlessResult = "Not tested";
  String _fallResult = "Not tested";
  String _locationResult = "Not tested";
  String _homeLocation = "Not set";
  StreamSubscription<bool>? _internetSubscription;
  StreamSubscription<bool>? _motionlessSubscription;
  StreamSubscription<bool>? _fallSubscription;
  StreamSubscription<bool>? _locationSubscription;

  Future<void> requestLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() {
          _homeLocation = "Location permission denied";
        });
      }
    }
  }

  Future<void> setHomeLocation() async {
    await requestLocationPermission();
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      await _sosPlugin.setHomeLocation(position.latitude, position.longitude);
      setState(() {
        _homeLocation = "Home location set to: ${position.latitude}, ${position.longitude}";
      });
    } catch (e) {
      setState(() {
        _homeLocation = "Error setting home location: $e";
      });
    }
  }

  void startMonitoring() {
    // Monitor Internet
    _internetSubscription?.cancel();
    _internetSubscription = _sosPlugin.internetStream.listen((isConnected) {
      setState(() {
        _internetResult = "Internet: $isConnected";
      });
    }, onError: (error) {
      setState(() {
        _internetResult = "Internet Error: $error";
      });
    });

    // Monitor Motionless
    _motionlessSubscription?.cancel();
    _motionlessSubscription = _sosPlugin.motionlessStream.listen((isMotionless) {
      setState(() {
        _motionlessResult = "Motionless (8 secs): $isMotionless";
      });
    }, onError: (error) {
      setState(() {
        _motionlessResult = "Motionless Error: $error";
      });
    });

    // Monitor Fall
    _fallSubscription?.cancel();
    _fallSubscription = _sosPlugin.fallStream.listen((fallDetected) {
      setState(() {
        _fallResult = "Fall Detected: $fallDetected";
      });
    }, onError: (error) {
      setState(() {
        _fallResult = "Fall Error: $error";
      });
    });

    // Monitor Location
    _locationSubscription?.cancel();
    _locationSubscription = _sosPlugin.locationStream.listen((isOutsideHome) {
      setState(() {
        _locationResult = "Outside Home (50m): $isOutsideHome";
      });
    }, onError: (error) {
      setState(() {
        _locationResult = "Location Error: $error";
      });
    });
  }

  void stopMonitoring() {
    _internetSubscription?.cancel();
    _motionlessSubscription?.cancel();
    _fallSubscription?.cancel();
    _locationSubscription?.cancel();
    setState(() {
      _internetResult = "Not tested";
      _motionlessResult = "Not tested";
      _fallResult = "Not tested";
      _locationResult = "Not tested";
    });
  }

  @override
  void dispose() {
    stopMonitoring();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: Text('SOS Plugin Test')),
        body: SingleChildScrollView(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    _homeLocation,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    _internetResult,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    _motionlessResult,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    _fallResult,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    _locationResult,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16),
                  ),
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: setHomeLocation,
                  child: Text('Set Home Location'),
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: startMonitoring,
                  child: Text('Start Monitoring'),
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: stopMonitoring,
                  child: Text('Stop Monitoring'),
                ),
                SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}