import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'data_connection_plugin_platform_interface.dart';

/// An implementation of [DataConnectionPluginPlatform] that uses method channels.
class MethodChannelDataConnectionPlugin extends DataConnectionPluginPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('data_connection_plugin');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
