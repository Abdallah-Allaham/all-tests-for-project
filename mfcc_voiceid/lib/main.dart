import 'package:flutter/material.dart';
import 'voice_id_screen.dart'; // استيراد VoiceIdScreen

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {


  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        //appBar: AppBar(title: const Text("Voice ID 🔐")),
        body: const VoiceIdScreen(), // إضافة VoiceIdScreen
      ),
    );
  }
}