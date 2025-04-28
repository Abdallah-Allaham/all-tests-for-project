import 'package:flutter_test/flutter_test.dart';
import 'package:data_connection_plugin/data_connection_plugin.dart';
import 'package:data_connection_plugin/data_connection_plugin_platform_interface.dart';
import 'package:data_connection_plugin/data_connection_plugin_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockDataConnectionPluginPlatform
    with MockPlatformInterfaceMixin
    implements DataConnectionPluginPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final DataConnectionPluginPlatform initialPlatform = DataConnectionPluginPlatform.instance;

  test('$MethodChannelDataConnectionPlugin is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelDataConnectionPlugin>());
  });

  test('getPlatformVersion', () async {
    DataConnectionPlugin dataConnectionPlugin = DataConnectionPlugin();
    MockDataConnectionPluginPlatform fakePlatform = MockDataConnectionPluginPlatform();
    DataConnectionPluginPlatform.instance = fakePlatform;

    expect(await dataConnectionPlugin.getPlatformVersion(), '42');
  });
}
