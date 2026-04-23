import 'package:flutter/services.dart';

class SecureScreen {
  static const MethodChannel _channel = MethodChannel('com.eschool/security');

  static Future<void> enableSecure() async {
    try {
      await _channel.invokeMethod('enableSecure');
    } catch (e) {
      print("Error enabling secure screen: $e");
    }
  }

  static Future<void> disableSecure() async {
    try {
      await _channel.invokeMethod('disableSecure');
    } catch (e) {
      print("Error disabling secure screen: $e");
    }
  }
}
