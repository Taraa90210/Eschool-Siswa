import 'package:eschool/utils/system/appLanguages.dart';
import 'package:eschool/utils/system/hiveBoxKeys.dart';
import 'package:hive/hive.dart';

class SettingsRepository {
  Future<void> setCurrentLanguageCode(String value) async {
    Hive.box(settingsBoxKey).put(currentLanguageCodeKey, value);
  }

  Future<void> setAllowNotification(bool value) async {
    Hive.box(settingsBoxKey).put(allowNotificationKey, value);
  }

  Future<void> setAllowVibration(bool value) async {
    Hive.box(settingsBoxKey).put(allowVibrationKey, value);
  }

  String getCurrentLanguageCode() {
    return Hive.box(settingsBoxKey).get(currentLanguageCodeKey) ??
        defaultLanguageCode;
  }

  bool getAllowNotification() {
    return Hive.box(settingsBoxKey).get(allowNotificationKey) ?? true;
  }

  bool getAllowVibration() {
    return Hive.box(settingsBoxKey).get(allowVibrationKey) ?? true;
  }
}
