import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  TextEditingController phoneNumberController = TextEditingController();
  TextEditingController nameController = TextEditingController();
  TextEditingController supervisorController = TextEditingController();

  SpeechToText speechToText = SpeechToText();
  FlutterTts flutterTts = FlutterTts();
  bool isListening = false;
  bool isSpeaking = false;
  String currentField = ''; // لتحديد الحقل الحالي

  @override
  void initState() {
    super.initState();
    initSttAndTts();
  }

  Future<void> initSttAndTts() async {
    // تهيئة Speech-to-Text
    bool available = await speechToText.initialize(
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') {
          setState(() {
            isListening = false;
          });
        }
      },
      onError: (error) => print('Error: $error'),
    );
    if (available) {
      setState(() {
        isListening = false; // نبدأ بدون استماع
      });
    } else {
      print("Speech to Text not available");
    }

    // تهيئة Text-to-Speech
    await flutterTts.setLanguage('ar-SA');
    await flutterTts.setPitch(1.0);
    await flutterTts.setSpeechRate(0.5);
    flutterTts.setCompletionHandler(() {
      setState(() {
        isSpeaking = false;
      });
      // بعد ما يخلّص التحدث، نبدأ الاستماع
      startListening();
    });
  }

  Future<void> startSignUpProcess() async {
    // 1. رقم الهاتف
    setState(() {
      currentField = 'phone';
    });
    await speak('أدخل رقم الهاتف');
  }

  Future<void> speak(String message) async {
    setState(() {
      isSpeaking = true;
    });
    await flutterTts.speak(message);
  }

  Future<void> startListening() async {
    if (!isListening) {
      setState(() {
        isListening = true;
      });
      await speechToText.listen(
        listenFor: const Duration(seconds: 7),
        localeId: 'ar-SA', // دعم اللغة العربية
        onResult: (result) {
          setState(() {
            if (result.finalResult) {
              // إذا كان الاستماع انتهى وفيه نتيجة نهائية
              if (currentField == 'phone') {
                phoneNumberController.text = result.recognizedWords;
                // الانتقال للخطوة التالية
                currentField = 'name';
                speak('أدخل الاسم');
              } else if (currentField == 'name') {
                nameController.text = result.recognizedWords;
                currentField = 'supervisor';
                speak('أدخل رقم هاتف المشرف');
              } else if (currentField == 'supervisor') {
                supervisorController.text = result.recognizedWords;
                currentField = '';
                speak('تم تسجيل البيانات بنجاح');
              }
            }
          });
        },
      );
    }
  }

  @override
  void dispose() {
    phoneNumberController.dispose();
    nameController.dispose();
    supervisorController.dispose();
    speechToText.stop();
    flutterTts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            TextField(
              controller: phoneNumberController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Phone Number',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: nameController,
              keyboardType: TextInputType.name,
              decoration: InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: supervisorController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Supervisor Phone Number',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: startSignUpProcess,
              child: const Text('بدء التسجيل الصوتي'),
            ),
          ],
        ),
      ),
    );
  }
}