import 'package:flutter/services.dart';

class ScreenCaptureProtection {
  static const MethodChannel _channel = MethodChannel('screen_capture_protection');

  static Future<void> enable() async {
    await _channel.invokeMethod('enableProtection');
  }

  static Future<void> disable() async {
    await _channel.invokeMethod('disableProtection');
  }
}
