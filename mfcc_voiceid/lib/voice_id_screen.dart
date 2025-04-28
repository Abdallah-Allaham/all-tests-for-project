import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:record/record.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:developer' as developer;

class VoiceIdScreen extends StatefulWidget {
  const VoiceIdScreen({super.key});

  @override
  VoiceIdScreenState createState() => VoiceIdScreenState();
}

class VoiceIdScreenState extends State<VoiceIdScreen> {
  final _record = AudioRecorder();
  final _audioPlayer = AudioPlayer();
  String? _recordedFilePath;
  String? _originalFilePath;
  bool _isRecording = false;
  String _audioFeatures = '';
  List<double>? _voiceIdFeatures;
  List<double>? _newFeatures;
  String? _firstSamplePath;
  String? _verificationSamplePath;
  static const MethodChannel _channel = MethodChannel('audio_processor');

  @override
  void initState() {
    super.initState();
    _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    final localContext = context;
    if (await Permission.microphone.request().isGranted) {
      // الإذن مُمنح
    } else {
      if (localContext.mounted) {
        ScaffoldMessenger.of(localContext).showSnackBar(
          const SnackBar(content: Text('Microphone permission is required')),
        );
      }
    }
  }

  Future<Map<String, dynamic>?> _extractFeatures(String filePath) async {
    try {
      final Map<dynamic, dynamic> result = await _channel.invokeMethod(
        'extractFeatures',
        {'filePath': filePath},
      );
      List<dynamic> featuresDynamic = result['features'] as List<dynamic>;
      List<double> features = featuresDynamic.map((e) => e as double).toList();
      String processedFilePath = result['processedFilePath'] as String;
      developer.log(
        'Extracted MFCC: ${features.map((e) => e.toStringAsFixed(2)).toList()}',
      );
      return {'features': features, 'processedFilePath': processedFilePath};
    } catch (e) {
      if (mounted) {
        setState(() {
          _audioFeatures = 'Failed to extract features: $e';
        });
      }
      return null;
    }
  }

  bool _isSilentVector(List<double> features) {
    if (features[18] == -1.0) return true; // 19 ميزة (MFCC فقط)
    double sumOfSquares = 0.0;
    for (int i = 0; i < features.length - 1; i++) {
      sumOfSquares += features[i] * features[i];
    }
    double magnitude = sqrt(sumOfSquares);
    return magnitude < 0.1;
  }

  Future<void> _startRecording() async {
    if (await Permission.microphone.isGranted) {
      setState(() {
        _isRecording = true;
        _audioFeatures = 'Recording voice sample... Please wait';
      });
      final recordSettings = RecordConfig(encoder: AudioEncoder.wav);

      final directory = await Directory.systemTemp.createTemp();
      final filePath = '${directory.path}/recording.wav';
      _originalFilePath = filePath;
      await _record.start(recordSettings, path: filePath);

      await Future.delayed(const Duration(seconds: 5));
      await _stopRecording();
    }
  }

  Future<void> _stopRecording() async {
    _recordedFilePath = await _record.stop();
    if (mounted) {
      setState(() {
        _isRecording = false;
        _audioFeatures = 'Processing audio...';
      });
    }

    if (_recordedFilePath != null) {
      final result = await _extractFeatures(_recordedFilePath!);
      if (result != null) {
        List<double> features = result['features'];
        String processedFilePath = result['processedFilePath'];

        if (_isSilentVector(features) || processedFilePath.isEmpty) {
          if (mounted) {
            setState(() {
              _audioFeatures =
                  'No voice detected in the recording. Please speak clearly.';
            });
          }
          return;
        }

        _voiceIdFeatures = features;
        _firstSamplePath = processedFilePath;
        if (mounted) {
          setState(() {
            _audioFeatures =
                'Voice ID Stored Successfully:\nStored Features:\nMFCC: ${_voiceIdFeatures!.map((e) => e.toStringAsFixed(2)).toList()}';
          });
        }
      }
    }
  }

  Future<void> _verifyVoice() async {
    if (_voiceIdFeatures == null) {
      if (mounted) {
        setState(() {
          _audioFeatures = 'No Voice ID stored. Please record a sample first.';
        });
      }
      return;
    }

    _newFeatures = null;
    _verificationSamplePath = null;

    if (await Permission.microphone.isGranted) {
      setState(() {
        _isRecording = true;
        _audioFeatures = 'Recording verification sample... Please wait';
      });
      final recordSettings = RecordConfig(encoder: AudioEncoder.wav);

      final directory = await Directory.systemTemp.createTemp();
      final filePath = '${directory.path}/recording.wav';
      _originalFilePath = filePath;
      await _record.start(recordSettings, path: filePath);

      await Future.delayed(const Duration(seconds: 5));
      _recordedFilePath = await _record.stop();
      if (mounted) {
        setState(() {
          _isRecording = false;
          _audioFeatures = 'Processing audio...';
        });
      }

      if (_recordedFilePath != null) {
        final result = await _extractFeatures(_recordedFilePath!);
        if (result != null) {
          List<double> newFeatures = result['features'];
          String processedFilePath = result['processedFilePath'];

          if (_isSilentVector(newFeatures) || processedFilePath.isEmpty) {
            if (mounted) {
              setState(() {
                _audioFeatures =
                    'No voice detected in the verification sample. Please speak clearly.';
              });
            }
            return;
          }

          _newFeatures = newFeatures;
          _verificationSamplePath = processedFilePath;
          final distance = _calculateEuclideanDistance(
            _voiceIdFeatures!,
            _newFeatures!,
          );
          final isMatch = distance < 1.0; // قللنا العتبة عشان التمييز يبقى أدق

          if (mounted) {
            setState(() {
              _audioFeatures = '''
Stored Voice ID Features:
MFCC: ${_voiceIdFeatures!.map((e) => e.toStringAsFixed(2)).toList()}

Verification Voice Features:
MFCC: ${_newFeatures!.map((e) => e.toStringAsFixed(2)).toList()}

Match Result: ${isMatch ? 'مطابق' : 'غير مطابق'}
Distance Score: ${distance.toStringAsFixed(2)} (Less than 1.0 means match)
''';
            });
          }
        }
      }
    }
  }

  double _calculateEuclideanDistance(
    List<double> vector1,
    List<double> vector2,
  ) {
    if (vector1.length != vector2.length) return double.infinity;

    double sumOfSquares = 0.0;
    for (int i = 0; i < vector1.length; i++) {
      double diff = vector1[i] - vector2[i];
      sumOfSquares += diff * diff;
    }
    return sqrt(sumOfSquares);
  }

  Future<void> _playAudio(String? filePath) async {
    if (filePath != null && filePath.isNotEmpty) {
      try {
        developer.log('Playing audio from: $filePath');
        await _audioPlayer.play(DeviceFileSource(filePath));
        developer.log('Audio playback started successfully');
      } catch (e) {
        developer.log('Error playing audio: $e');
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error playing audio: $e')));
        }
      }
    } else {
      developer.log('No audio file available to play');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No audio file available to play.')),
        );
      }
    }
  }

  @override
  void dispose() {
    _record.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Voice ID 🔒')),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isRecording ? null : _startRecording,
                child: Text(
                  _isRecording ? 'Recording...' : 'Record Voice Sample (5s)',
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isRecording ? null : _verifyVoice,
                child: const Text('Verify Voice'),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _playAudio(_firstSamplePath),
                      child: const Text('Play Voice Sample'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _playAudio(_verificationSamplePath),
                      child: const Text('Play Verification Sample'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () => _playAudio(_originalFilePath),
                child: const Text('Play Original Recording'),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  _audioFeatures.isNotEmpty
                      ? 'Voice Features:\n$_audioFeatures'
                      : 'No features available.\nPlease record a sample to store Voice ID.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
