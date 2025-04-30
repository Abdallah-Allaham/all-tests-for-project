import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

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
  bool _isRecording = false;
  String _progressMessage = "";
  double _enrollmentPercentage = 0.0;
  bool _isProfileEnrolled = false;

  @override
  void initState() {
    super.initState();
    Permission.microphone.request();
    Permission.systemAlertWindow.request();
    _initEagle();
    _setupMethodChannelListener();
    _checkProfileEnrolled();
  }

  Future<void> _initEagle() async {
    try {
      await platform.invokeMethod('initEagle');
    } on PlatformException catch (e) {
    }
  }

  Future<void> _checkProfileEnrolled() async {
    try {
      bool isEnrolled = await platform.invokeMethod('isProfileEnrolled');
      setState(() {
        _isProfileEnrolled = isEnrolled;
      });
    } on PlatformException catch (e) {
      setState(() {
        _isProfileEnrolled = false;
      });
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
        _isProfileEnrolled = true; // بعد التسجيل الناجح، نحدّث حالة التسجيل
      });
    } on PlatformException catch (e) {
      setState(() {
        _progressMessage = "Failed to enroll voice: ${e.message}";
      });
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
    } on PlatformException catch (e) {
      setState(() {
        _progressMessage = "Failed to verify voice: ${e.message}";
      });
    } finally {
      setState(() {
        _isRecording = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Voice ID App")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (!_isProfileEnrolled) ...[
              ElevatedButton(
                onPressed: _isRecording ? null : _enrollVoice,
                child: Text("Enroll Voice"),
              ),
              SizedBox(height: 20),
            ],
            ElevatedButton(
              onPressed: _isRecording || !_isProfileEnrolled ? null : _verifyVoice,
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