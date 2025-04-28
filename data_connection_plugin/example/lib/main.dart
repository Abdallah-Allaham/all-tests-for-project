import 'package:flutter/material.dart';
import 'package:data_connection_plugin/data_connection_plugin.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  Future<void> _checkConnection() async {
    bool isConnected = await DataConnectionPlugin.getConnectionStatus();
    String connectionType = await DataConnectionPlugin.getConnectionType();
    print('Connected: $isConnected');
    print('Connection Type: $connectionType');
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: Text('Data Connection Plugin Demo')),
        body: Center(
          child: ElevatedButton(
            onPressed: _checkConnection,
            child: Text('Check Connection'),
          ),
        ),
      ),
    );
  }
}