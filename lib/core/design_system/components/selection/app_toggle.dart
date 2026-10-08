import 'package:flutter/cupertino.dart';

import '../../foundations/app_haptics.dart';
import '../../foundations/context_extensions.dart';
import '../../tokens/app_spacing.dart';

/// Açma/kapama anahtarı (DESIGN_SYSTEM.md §10 "Toggle"): `CupertinoSwitch`, açık `brand`,
/// kapalı `trackOff`. Her değişimde light haptic; dokunma alanı en az 44 yükseklikte.
class AppToggle extends StatelessWidget {
  const AppToggle({
    super.key,
    required this.value,
    required this.onChanged,
    required this.semanticLabel,
  });

  final bool value;

  /// Null ise pasif.
  final ValueChanged<bool>? onChanged;

  /// VoiceOver etiketi (örn. "Bildirimler"); yerelleştirilmiş olmalı.
  final String semanticLabel;

  void _set(bool next) {
    AppHaptics.light();
    onChanged?.call(next);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return MergeSemantics(
      child: Semantics(
        label: semanticLabel,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          // Anahtarın kendi alanı dışındaki 44'lük bölgeye dokunuş.
          onTap: onChanged == null ? null : () => _set(!value),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: AppSpacing.touchTarget,
            ),
            child: Center(
              widthFactor: 1,
              child: CupertinoSwitch(
                value: value,
                onChanged: onChanged == null ? null : _set,
                activeTrackColor: c.brand,
                inactiveTrackColor: c.trackOff,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
