import 'package:flutter/services.dart';

class DataConnectionPlugin {
  static const MethodChannel _channel = MethodChannel('data_connection');

  static Future<bool> getConnectionStatus() async {
    try {
      final bool isConnected = await _channel.invokeMethod('getConnectionStatus');
      return isConnected;
    } catch (e) {
      print('Error getting connection status: $e');
      return false;
    }
  }

  static Future<String> getConnectionType() async {
    try {
      final String connectionType = await _channel.invokeMethod('getConnectionType');
      return connectionType;
    } catch (e) {
      print('Error getting connection type: $e');
      return 'NONE';
    }
  }
}