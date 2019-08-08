import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_platform_plugin/share_platform_plugin.dart';

void main() {
  const MethodChannel channel = MethodChannel('share_platform_plugin');

  setUp(() {
    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      return '42';
    });
  });

  tearDown(() {
    channel.setMockMethodCallHandler(null);
  });

  test('getPlatformVersion', () async {
    expect(await SharePlatformPlugin.platformVersion, '42');
  });
}
