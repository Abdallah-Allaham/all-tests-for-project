import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

class YoloScreen extends StatefulWidget {
  const YoloScreen({super.key});

  @override
  State<YoloScreen> createState() => _YoloScreenState();
}

class _YoloScreenState extends State<YoloScreen> {
  String? statusMessage;

  Future<void> pickAndSendVideo() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.video);

    if (result != null && result.files.isNotEmpty) {
      final videoPath = result.files.single.path!;

      // 🧠 هنا ترسل الفيديو لموديل الذكاء الاصطناعي
      // مثال: await sendToModel(videoPath);
      await Future.delayed(const Duration(seconds: 2)); // محاكاة التأخير

      setState(() {
        statusMessage = "✅ تم الإرسال بنجاح";
      });
    } else {
      setState(() {
        statusMessage = "🚫 لم يتم اختيار فيديو";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("إرسال فيديو إلى الموديل")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: pickAndSendVideo,
              child: const Text("📂 اختر فيديو وأرسله"),
            ),
            const SizedBox(height: 20),
            if (statusMessage != null)
              Text(
                statusMessage!,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
          ],
        ),
      ),
    );
  }
}
