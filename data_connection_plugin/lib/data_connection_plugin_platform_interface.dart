import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'data_connection_plugin_method_channel.dart';

abstract class DataConnectionPluginPlatform extends PlatformInterface {
  /// Constructs a DataConnectionPluginPlatform.
  DataConnectionPluginPlatform() : super(token: _token);

  static final Object _token = Object();

  static DataConnectionPluginPlatform _instance = MethodChannelDataConnectionPlugin();

  /// The default instance of [DataConnectionPluginPlatform] to use.
  ///
  /// Defaults to [MethodChannelDataConnectionPlugin].
  static DataConnectionPluginPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [DataConnectionPluginPlatform] when
  /// they register themselves.
  static set instance(DataConnectionPluginPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
