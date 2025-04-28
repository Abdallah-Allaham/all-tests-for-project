import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'sos_plugin_platform_interface.dart';

/// An implementation of [SosPluginPlatform] that uses method channels.
class MethodChannelSosPlugin extends SosPluginPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('sos_plugin');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
