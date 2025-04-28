import 'package:flutter/material.dart';
import 'package:data_connection_plugin/data_connection_plugin.dart';

void main() {
  runApp(TestPluginApp());
}

class TestPluginApp extends StatefulWidget {
  @override
  _TestPluginAppState createState() => _TestPluginAppState();
}

class _TestPluginAppState extends State<TestPluginApp> {
  String _connectionStatus = "Press the button to check connection";

  // دالة للتحقق من الاتصال
  Future<void> _checkConnection() async {
    bool isConnected = await DataConnectionPlugin.getConnectionStatus();
    String connectionType = await DataConnectionPlugin.getConnectionType();

    setState(() {
      if (isConnected) {
        if (connectionType == "WIFI") {
          _connectionStatus = "You are Connected to Wi-Fi";
        } else if (connectionType == "MOBILE") {
          _connectionStatus = "You are Connected to Mobile";
        } else {
          _connectionStatus = "Connected via an unknown network";
        }
      } else {
        _connectionStatus = "You are not Connected to the internet";
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text('Connection Checker'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _connectionStatus,
                style: TextStyle(fontSize: 20),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20), // 
              ElevatedButton(
                onPressed: _checkConnection,
                child: Text('Check Connection'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}