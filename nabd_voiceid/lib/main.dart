import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_tts/flutter_tts.dart';

void main() {
  runApp(VoiceIdApp());
}

class VoiceIdApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: VoiceIdScreen(),
    );
  }
}

class VoiceIdScreen extends StatefulWidget {
  @override
  _VoiceIdScreenState createState() => _VoiceIdScreenState();
}

class _VoiceIdScreenState extends State<VoiceIdScreen> {
  static const platform = MethodChannel('voice_id_app/eagle');
  final FlutterTts _tts = FlutterTts();
  bool _isRecording = false;
  String _progressMessage = "";
  double _enrollmentPercentage = 0.0;

  @override
  void initState() {
    super.initState();
    _requestPermissions();
    _initEagle();
    _setupMethodChannelListener();
    //_speak("Welcome to Voice ID App. Press the first button to enroll your voice, or the second button to verify.");
  }

  Future<void> _requestPermissions() async {
    await Permission.microphone.request();
  }

  Future<void> _initEagle() async {
    try {
      String result = await platform.invokeMethod('initEagle');
      print(result);
    } on PlatformException catch (e) {
      print("Failed to init Eagle: ${e.message}");
    }
  }

  void _setupMethodChannelListener() {
    platform.setMethodCallHandler((call) async {
      if (call.method == "updateProgress") {
        setState(() {
          _enrollmentPercentage = call.arguments as double;
          _progressMessage = "Enrollment progress: ${_enrollmentPercentage.toStringAsFixed(1)}%";
        });
      }
      return null;
    });
  }

  Future<void> _enrollVoice() async {
    setState(() {
      _isRecording = true;
      _progressMessage = "Recording... Please speak clearly for 10-15 seconds.";
      _enrollmentPercentage = 0.0;
    });

    try {
      String result = await platform.invokeMethod('enrollVoice');
      setState(() {
        _progressMessage = result;
      });
      if (result == "تم") {
        await _speak("تم");
      }
    } on PlatformException catch (e) {
      setState(() {
        _progressMessage = "Failed to enroll voice: ${e.message}";
      });
      await _speak("Failed to enroll voice: ${e.message}");
    } finally {
      setState(() {
        _isRecording = false;
      });
    }
  }

  Future<void> _verifyVoice() async {
    setState(() {
      _isRecording = true;
      _progressMessage = "Verifying... Please speak now.";
    });

    try {
      String result = await platform.invokeMethod('verifyVoice');
      setState(() {
        _progressMessage = result;
      });
      await _speak(result);
    } on PlatformException catch (e) {
      setState(() {
        _progressMessage = "Failed to verify voice: ${e.message}";
      });
      await _speak(e.message ?? "Failed to verify voice");
    } finally {
      setState(() {
        _isRecording = false;
      });
    }
  }

  Future<void> _speak(String text) async {
    await _tts.setLanguage("en-US");
    await _tts.setSpeechRate(0.5);
    await _tts.speak(text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Voice ID App")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: _isRecording ? null : _enrollVoice,
              child: Text("Enroll Voice"),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isRecording ? null : _verifyVoice,
              child: Text("Verify Voice"),
            ),
            SizedBox(height: 20),
            if (_isRecording || _progressMessage.isNotEmpty) ...[
              CircularProgressIndicator(
                value: _enrollmentPercentage / 100,
                backgroundColor: Colors.grey[300],
              ),
              SizedBox(height: 20),
              Text(
                _progressMessage,
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}