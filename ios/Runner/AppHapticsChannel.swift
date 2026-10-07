import Flutter
import UIKit

/// Dart tarafındaki `AppHaptics` için native haptic kanalı.
/// Flutter'ın `HapticFeedback`'inde olmayan `rigid` ve notification (success/error) tiplerini sağlar.
final class AppHapticsChannel {
  static let channelName = "iagree/haptics"

  private let channel: FlutterMethodChannel

  // Generator'lar bir kez yaratılır; her tetiklemeden sonra prepare() çağrılarak Taptic Engine
  // sıcak tutulur, böylece sonraki titreşim gecikmesiz gelir.
  private let selection = UISelectionFeedbackGenerator()
  private let light = UIImpactFeedbackGenerator(style: .light)
  private let medium = UIImpactFeedbackGenerator(style: .medium)
  private let rigid = UIImpactFeedbackGenerator(style: .rigid)
  private let notification = UINotificationFeedbackGenerator()

  init(messenger: FlutterBinaryMessenger) {
    channel = FlutterMethodChannel(name: Self.channelName, binaryMessenger: messenger)
    channel.setMethodCallHandler { [weak self] call, result in
      guard let self else {
        result(nil)
        return
      }
      self.handle(call, result: result)
    }
  }

  private func handle(_ call: FlutterMethodCall, result: FlutterResult) {
    switch call.method {
    case "selection":
      selection.selectionChanged()
      selection.prepare()
    case "light":
      light.impactOccurred()
      light.prepare()
    case "medium":
      medium.impactOccurred()
      medium.prepare()
    case "rigid":
      rigid.impactOccurred()
      rigid.prepare()
    case "success":
      notification.notificationOccurred(.success)
      notification.prepare()
    case "error":
      notification.notificationOccurred(.error)
      notification.prepare()
    default:
      result(FlutterMethodNotImplemented)
      return
    }
    result(nil)
  }
}
