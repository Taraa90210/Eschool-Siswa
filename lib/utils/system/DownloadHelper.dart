import 'dart:io';
import 'package:flutter/services.dart';

class MediaStoreHelper {
  static const MethodChannel _channel = MethodChannel('com.eschool/mediastore');

  /// Save file from [filePath] to Downloads folder with [fileName] and [mimeType]
  static Future<bool> saveToDownloads({
    required String filePath,
    required String fileName,
    String mimeType = "application/octet-stream",
  }) async {
    if (!File(filePath).existsSync()) return false;

    try {
      final bool result = await _channel.invokeMethod('saveToDownloads', {
        "filePath": filePath,
        "fileName": fileName,
        "mimeType": mimeType,
      });
      return result;
    } catch (e) {
      print("Error saving file to downloads: $e");
      return false;
    }
  }
}
