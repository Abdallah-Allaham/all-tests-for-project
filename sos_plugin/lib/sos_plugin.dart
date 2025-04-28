import 'dart:async';
import 'package:flutter/services.dart';

class SosPlugin {
  static const EventChannel _internetChannel = EventChannel('sos_plugin/internet');
  static const EventChannel _motionlessChannel = EventChannel('sos_plugin/motionless');
  static const EventChannel _fallChannel = EventChannel('sos_plugin/fall');
  static const EventChannel _locationChannel = EventChannel('sos_plugin/location');
  static const MethodChannel _channel = MethodChannel('sos_plugin');

  Stream<bool> get internetStream => _internetChannel
      .receiveBroadcastStream()
      .map<bool>((value) => value as bool);

  Stream<bool> get motionlessStream => _motionlessChannel
      .receiveBroadcastStream()
      .map<bool>((value) => value as bool);

  Stream<bool> get fallStream => _fallChannel
      .receiveBroadcastStream()
      .map<bool>((value) => value as bool);

  Stream<bool> get locationStream => _locationChannel
      .receiveBroadcastStream()
      .map<bool>((value) => value as bool);

  Future<void> setHomeLocation(double latitude, double longitude) async {
    await _channel.invokeMethod('setHomeLocation', {
      'latitude': latitude,
      'longitude': longitude,
    });
  }
}