import 'dart:async';

import 'package:flutter/services.dart';

class SharePlatformPlugin {
  static const MethodChannel _channel =
      const MethodChannel('share_platform_plugin');

  static Future<String> get platformVersion async {
    final String version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }
}
