import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  CameraController? _cameraController;
  bool _isCameraInitialized = false;

  Future<void> initializeCamera() async {
    final cameras = await availableCameras();
    final camera = cameras.first;

    _cameraController = CameraController(camera, ResolutionPreset.medium);
    await _cameraController!.initialize();

    setState(() {
      _isCameraInitialized = true;
    });
  }

  void startStreaming() async {
    if (!_isCameraInitialized) {
      await initializeCamera();
    }
    print("بدأ الإرسال للـ AI");
  }

  void stopStreaming() {
    if (_cameraController != null) {
      _cameraController!.dispose();
      _cameraController = null;
    }
    setState(() {
      _isCameraInitialized = false;
    });
    print("تم إيقاف الإرسال والكاميرا");
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Camera Streaming')),
      body: Column(
        children: [
          if (_isCameraInitialized && _cameraController != null)
            Container(
              height: 600, // زيادة الارتفاع حسب طلبك
              width: double.infinity,
              child: CameraPreview(_cameraController!),
            )
          else
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text("الكاميرا غير مفعلة"),
            ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: startStreaming,
                child: const Text("تشغيل الكاميرا والإرسال"),
              ),
              ElevatedButton(
                onPressed: stopStreaming,
                child: const Text("إيقاف الكاميرا والإرسال"),
              ),
            ],
          )
        ],
      ),
    );
  }
}
