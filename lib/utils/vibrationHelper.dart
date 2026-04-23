import 'package:eschool/data/repositories/system/settingsRepository.dart';
import 'package:vibration/vibration.dart';

/// Helper class for managing vibrations throughout the app
/// 
/// This class provides two types of vibrations:
/// 1. Regular vibrations that respect user settings (vibrateIfEnabled methods)
/// 2. Security vibrations for exams that bypass user settings (examSecurityVibration)
class VibrationHelper {
  static final SettingsRepository _settingsRepository = SettingsRepository();

  /// Triggers vibration if the user has enabled it in settings
  static Future<void> vibrateIfEnabled({
    int duration = 100,
    List<int>? pattern,
    int repeat = -1,
  }) async {
    try {
      // Check if vibration is enabled in user settings
      final isVibrationEnabled = _settingsRepository.getAllowVibration();
      
      if (!isVibrationEnabled) {
        return; // Don't vibrate if disabled in settings
      }

      // Check if device supports vibration
      final hasVibrator = await Vibration.hasVibrator();
      if (hasVibrator != true) {
        return; // Device doesn't support vibration
      }

      // Trigger vibration based on parameters
      if (pattern != null) {
        await Vibration.vibrate(pattern: pattern, repeat: repeat);
      } else {
        await Vibration.vibrate(duration: duration);
      }
    } catch (e) {
      // Silently handle any vibration errors
      print('Vibration error: $e');
    }
  }

  /// Enhanced vibration for notifications
  static Future<void> notificationVibration() async {
    await vibrateIfEnabled(duration: 800); // Single long vibration that's more noticeable
  }

  /// Strong vibration for important notifications
  static Future<void> strongNotificationVibration() async {
    await vibrateIfEnabled(
      pattern: [0, 500, 150, 500, 150, 300], // Triple pattern for important notifications
    );
  }

  /// Short vibration for button taps
  static Future<void> buttonTapVibration() async {
    await vibrateIfEnabled(duration: 50);
  }

  /// Strong vibration for alerts
  static Future<void> alertVibration() async {
    await vibrateIfEnabled(
      pattern: [0, 500, 150, 500], // Strong double vibration for alerts
    );
  }

  /// Force vibration for exam security (ignores user settings)
  /// This is used for exam integrity features and will always vibrate
  /// regardless of user's vibration preference
  static Future<void> examSecurityVibration({
    int duration = 500,
    List<int>? pattern,
  }) async {
    try {
      // Check if device supports vibration
      final hasVibrator = await Vibration.hasVibrator();
      if (hasVibrator != true) {
        return; // Device doesn't support vibration
      }

      // Force vibration regardless of user settings for exam security
      if (pattern != null) {
        await Vibration.vibrate(pattern: pattern);
      } else {
        await Vibration.vibrate(duration: duration);
      }
    } catch (e) {
      // Silently handle any vibration errors
      print('Exam security vibration error: $e');
    }
  }

  /// Exam app switch detection vibration (security feature)
  static Future<void> examAppSwitchAlert() async {
    await examSecurityVibration(
      pattern: [0, 500, 200, 500, 200, 500], // Strong triple vibration
    );
  }

  /// Exam time warning vibration (security feature)
  static Future<void> examTimeWarning() async {
    await examSecurityVibration(
      pattern: [0, 300, 100, 300], // Double vibration warning
    );
  }

  /// Success vibration pattern
  static Future<void> successVibration() async {
    await vibrateIfEnabled(
      pattern: [0, 150, 80, 150, 80, 150], // Triple short vibration for success
    );
  }

  /// Error vibration pattern
  static Future<void> errorVibration() async {
    await vibrateIfEnabled(
      pattern: [0, 600, 150, 300], // Long-short pattern for error
    );
  }

  /// Cancel any ongoing vibration
  static Future<void> cancel() async {
    try {
      await Vibration.cancel();
    } catch (e) {
      print('Error canceling vibration: $e');
    }
  }
}
