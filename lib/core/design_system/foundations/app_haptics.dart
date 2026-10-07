import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Titreşim (DESIGN_SYSTEM.md §13). Ekranlar yalnızca bunu çağırır.
///
/// iOS'ta native kanal (`ios/Runner/AppHapticsChannel.swift`); diğer platformlarda Flutter'ın
/// `HapticFeedback`'ine düşer. Hiçbir koşulda hata fırlatmaz.
abstract final class AppHaptics {
  @visibleForTesting
  static const MethodChannel channel = MethodChannel('iagree/haptics');

  /// Chip, segmented, stepper adımı, deste eşiği.
  static void selection() => _fire('selection', HapticFeedback.selectionClick);

  /// Olur, Pas, Geri al, Dürt, toggle.
  static void light() => _fire('light', HapticFeedback.lightImpact);

  /// Çok isterim, karar anı teması.
  static void medium() => _fire('medium', HapticFeedback.mediumImpact);

  /// Olmaz. Android'de en yakın karşılığı heavyImpact.
  static void rigid() => _fire('rigid', HapticFeedback.heavyImpact);

  /// Desteyi gönderme, karar anı Arc %100. Android'de mediumImpact.
  static void success() => _fire('success', HapticFeedback.mediumImpact);

  /// Eksik alanla CTA. Android'de heavyImpact.
  static void error() => _fire('error', HapticFeedback.heavyImpact);

  static void _fire(String method, Future<void> Function() fallback) {
    final Future<void> call;
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
      call = channel.invokeMethod<void>(method);
    } else {
      call = fallback();
    }
    call.catchError((Object _) {});
  }
}
