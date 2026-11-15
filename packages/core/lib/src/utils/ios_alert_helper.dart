import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Bridges native iOS system alert playback and haptic feedback when
/// Flutter's [SystemSound.play(SystemSoundType.alert)] is a no-op on mobile.
class IosAlertHelper {
  IosAlertHelper._();

  static const MethodChannel _channel = MethodChannel(
    'com.otlobegy/audio_session',
  );

  /// Plays a native iOS attention alert sound (on iOS) along with heavy
  /// haptic feedback on mobile devices.
  static Future<void> playAlert({bool haptic = true}) async {
    if (haptic && !kIsWeb) {
      try {
        await HapticFeedback.heavyImpact();
      } catch (_) {}
    }

    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
      try {
        await _channel.invokeMethod<void>('playAlertSound');
      } on MissingPluginException {
        // Ignore in headless tests or unsupported runners.
      } catch (_) {}
    } else {
      try {
        await SystemSound.play(SystemSoundType.alert);
      } catch (_) {}
    }
  }
}
