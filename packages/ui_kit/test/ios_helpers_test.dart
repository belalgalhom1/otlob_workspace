import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_kit/ui_kit.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('VoiceAudioHelper', () {
    test('uses cross-platform .m4a and Codec.aacMP4 on mobile', () {
      expect(VoiceAudioHelper.recordingExtension, 'm4a');
      expect(VoiceAudioHelper.recordingCodec, Codec.aacMP4);

      final path = VoiceAudioHelper.buildRecordingPath('/tmp/cache');
      expect(path, matches(r'^/tmp/cache/recording_\d+\.m4a$'));
    });

    test('codecFromSource maps legacy and cross-platform formats accurately', () {
      expect(
        VoiceAudioHelper.codecFromSource('https://cdn.example.com/voice.m4a?v=1'),
        Codec.aacMP4,
      );
      expect(VoiceAudioHelper.codecFromSource('/tmp/audio.mp4'), Codec.aacMP4);
      expect(VoiceAudioHelper.codecFromSource('/tmp/legacy.aac'), Codec.aacADTS);
      expect(VoiceAudioHelper.codecFromSource('/tmp/clip.mp3'), Codec.mp3);
      expect(VoiceAudioHelper.codecFromSource('/tmp/clip.wav'), Codec.pcm16WAV);
      expect(VoiceAudioHelper.codecFromSource('/tmp/clip.opus'), Codec.opusOGG);
      expect(VoiceAudioHelper.codecFromSource('/tmp/clip.caf'), Codec.opusCAF);
    });

    test('invokes AVAudioSession channel only on iOS', () async {
      final calls = <String>[];
      const channel = MethodChannel('com.otlobegy/audio_session');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        calls.add(call.method);
        return null;
      });
      addTearDown(() {
        debugDefaultTargetPlatformOverride = null;
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, null);
      });

      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      await VoiceAudioHelper.configureForPlayback();
      await VoiceAudioHelper.configureForRecording();
      expect(calls, isEmpty);

      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      await VoiceAudioHelper.configureForPlayback();
      await VoiceAudioHelper.configureForRecording();
      expect(calls, ['configurePlayback', 'configurePlayAndRecord']);
    });
  });

  group('MediaPermissionHelper', () {
    test('detects camera and photo library access denial codes', () {
      expect(
        MediaPermissionHelper.isAccessDeniedError(
          PlatformException(code: 'camera_access_denied'),
        ),
        isTrue,
      );
      expect(
        MediaPermissionHelper.isAccessDeniedError(
          PlatformException(code: 'photo_access_denied'),
        ),
        isTrue,
      );
      expect(
        MediaPermissionHelper.isAccessDeniedError(
          PlatformException(code: 'photo_access_restricted'),
        ),
        isTrue,
      );
      expect(
        MediaPermissionHelper.isAccessDeniedError(Exception('other')),
        isFalse,
      );
    });

    testWidgets('shows localized Settings SnackBar for iOS access denials', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  MediaPermissionHelper.handlePickerError(
                    PlatformException(code: 'photo_access_denied'),
                    context: context,
                  );
                },
                child: const Text('Pick'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Pick'));
      await tester.pump();

      expect(
        find.text('Please allow photo library access in Settings'),
        findsOneWidget,
      );
      expect(find.text('Settings'), findsOneWidget);
    });
  });
}
