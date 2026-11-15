import AVFoundation
import AudioToolbox
import Flutter
import UIKit
import UserNotifications
import flutter_local_notifications

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private var audioChannel: FlutterMethodChannel?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    UNUserNotificationCenter.current().delegate = self as UNUserNotificationCenterDelegate
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    FlutterLocalNotificationsPlugin.setPluginRegistrantCallback { registry in
      GeneratedPluginRegistrant.register(with: registry)
    }
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "OtlobAudioSession") {
      let channel = FlutterMethodChannel(
        name: "com.otlobegy/audio_session",
        binaryMessenger: registrar.messenger()
      )
      channel.setMethodCallHandler { call, result in
        let session = AVAudioSession.sharedInstance()
        do {
          switch call.method {
          case "configurePlayback":
            try session.setCategory(.playback, mode: .default, options: [])
            try session.setActive(true)
            result(nil)
          case "configurePlayAndRecord":
            try session.setCategory(
              .playAndRecord,
              mode: .default,
              options: [.defaultToSpeaker, .allowBluetoothA2DP, .allowBluetooth]
            )
            try session.setActive(true)
            result(nil)
          case "playAlertSound":
            AudioServicesPlaySystemSound(1007)
            result(nil)
          default:
            result(FlutterMethodNotImplemented)
          }
        } catch {
          result(
            FlutterError(
              code: "AUDIO_SESSION_ERROR",
              message: error.localizedDescription,
              details: nil
            )
          )
        }
      }
      audioChannel = channel
    }
  }
}
