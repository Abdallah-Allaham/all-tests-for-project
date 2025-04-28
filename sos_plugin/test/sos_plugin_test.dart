import 'package:flutter_test/flutter_test.dart';
import 'package:sos_plugin/sos_plugin.dart';
import 'package:sos_plugin/sos_plugin_platform_interface.dart';
import 'package:sos_plugin/sos_plugin_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockSosPluginPlatform
    with MockPlatformInterfaceMixin
    implements SosPluginPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final SosPluginPlatform initialPlatform = SosPluginPlatform.instance;

  test('$MethodChannelSosPlugin is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelSosPlugin>());
  });

  test('getPlatformVersion', () async {
    SosPlugin sosPlugin = SosPlugin();
    MockSosPluginPlatform fakePlatform = MockSosPluginPlatform();
    SosPluginPlatform.instance = fakePlatform;

    expect(await sosPlugin.getPlatformVersion(), '42');
  });
}
