import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_sound/flutter_sound.dart';

/// Shared helper for cross-platform voice recording/playback codecs and iOS
/// `AVAudioSession` speaker/microphone routing.
class VoiceAudioHelper {
  VoiceAudioHelper._();

  static const MethodChannel _channel = MethodChannel(
    'com.otlobegy/audio_session',
  );

  /// Cross-platform audio extension natively supported by both iOS AVFoundation
  /// and Android MediaRecorder, as well as the backend media upload allowlist.
  static String get recordingExtension => kIsWeb ? 'webm' : 'm4a';

  /// Recording codec matching [recordingExtension].
  static Codec get recordingCodec =>
      kIsWeb ? Codec.defaultCodec : Codec.aacMP4;

  /// Builds a timestamped temporary recording path with the platform codec
  /// extension.
  static String buildRecordingPath(
    String directoryPath, {
    String prefix = 'recording',
  }) {
    final ts = DateTime.now().millisecondsSinceEpoch;
    return '$directoryPath/${prefix}_$ts.$recordingExtension';
  }

  /// Infers the [FlutterSoundPlayer] codec from a URL or file path so legacy
  /// `.aac` uploads and cross-platform `.m4a` uploads both play cleanly on iOS.
  static Codec codecFromSource(String source) {
    final clean = source.split('?').first.split('#').first.toLowerCase();
    if (clean.endsWith('.m4a') || clean.endsWith('.mp4')) {
      return Codec.aacMP4;
    }
    if (clean.endsWith('.aac')) {
      return Codec.aacADTS;
    }
    if (clean.endsWith('.mp3')) {
      return Codec.mp3;
    }
    if (clean.endsWith('.wav')) {
      return Codec.pcm16WAV;
    }
    if (clean.endsWith('.ogg') || clean.endsWith('.opus')) {
      return Codec.opusOGG;
    }
    if (clean.endsWith('.caf')) {
      return Codec.opusCAF;
    }
    return Codec.aacADTS;
  }

  /// Configures iOS `AVAudioSession` for loudspeaker playback so voice notes
  /// play at full volume rather than falling back to the ear receiver.
  static Future<void> configureForPlayback() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.iOS) return;
    try {
      await _channel.invokeMethod<void>('configurePlayback');
    } on MissingPluginException {
      // Ignore in widget tests or runners without the channel registered.
    } catch (_) {}
  }

  /// Configures iOS `AVAudioSession` for microphone recording with speaker and
  /// Bluetooth headset support.
  static Future<void> configureForRecording() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.iOS) return;
    try {
      await _channel.invokeMethod<void>('configurePlayAndRecord');
    } on MissingPluginException {
      // Ignore in widget tests or runners without the channel registered.
    } catch (_) {}
  }
}
