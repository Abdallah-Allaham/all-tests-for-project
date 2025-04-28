import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'sos_plugin_method_channel.dart';

abstract class SosPluginPlatform extends PlatformInterface {
  /// Constructs a SosPluginPlatform.
  SosPluginPlatform() : super(token: _token);

  static final Object _token = Object();

  static SosPluginPlatform _instance = MethodChannelSosPlugin();

  /// The default instance of [SosPluginPlatform] to use.
  ///
  /// Defaults to [MethodChannelSosPlugin].
  static SosPluginPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [SosPluginPlatform] when
  /// they register themselves.
  static set instance(SosPluginPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
