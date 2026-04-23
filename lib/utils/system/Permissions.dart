import 'dart:io';
import 'package:permission_handler/permission_handler.dart';

Future<void> requestStoragePermission() async {
  if (Platform.isAndroid) {
    int sdkInt = int.parse(Platform.version.split(" ")[0]); // ambil SDK version
    if (sdkInt <= 28) { // Android 9 Pie = 28
      await Permission.storage.request();
    }
  }
}
