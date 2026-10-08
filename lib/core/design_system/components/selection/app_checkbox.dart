import 'package:flutter/widgets.dart';

import '../../foundations/app_haptics.dart';
import '../../foundations/app_icons.dart';
import '../../foundations/app_pressable.dart';
import '../../tokens/app_radius.dart';
import '../../tokens/app_spacing.dart';
import 'app_selection_mark.dart';

/// Onay kutusu (DESIGN_SYSTEM.md §10): 22'lik kutu, `radius xs`, 1,5px `borderControl`;
/// seçilince `brand` + `onBrand` ✓. Yalnızca onay metinlerinde kullanılır. Dokunma alanı 44×44.
class AppCheckbox extends StatelessWidget {
  const AppCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
    required this.semanticLabel,
  });

  final bool value;

  /// Yeni değeri verir; null ise pasif.
  final ValueChanged<bool>? onChanged;

  /// VoiceOver etiketi (onay metni); yerelleştirilmiş olmalı.
  final String semanticLabel;

  static const double size = 22;

  @override
  Widget build(BuildContext context) {
    return AppPressable(
      onPressed: onChanged == null
          ? null
          : () {
              AppHaptics.selection();
              onChanged!(!value);
            },
      semanticLabel: semanticLabel,
      semanticChecked: value,
      scaleOnPress: false,
      focusShape: AppRadius.border(AppRadius.xs),
      builder: (context, pressed) => SizedBox.square(
        dimension: AppSpacing.touchTarget,
        child: Center(
          child: AppSelectionMark(
            selected: value,
            enabled: onChanged != null,
            size: size,
            iconSize: AppIconSize.s14,
          ),
        ),
      ),
    );
  }
}
