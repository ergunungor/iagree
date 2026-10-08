import 'package:flutter/widgets.dart';

import '../../foundations/app_haptics.dart';
import '../../foundations/app_icons.dart';
import '../../foundations/app_pressable.dart';
import '../../tokens/app_spacing.dart';
import 'app_selection_mark.dart';

/// Listede çoklu (ya da sonuçlarda tekli) seçim dairesi (DESIGN_SYSTEM.md §10): 24'lük daire,
/// 1,5px `borderControl`; seçilince `brand` + `onBrand` ✓.
///
/// [onChanged] verilirse kendi başına dokunulabilir (44×44 alan). Null verilirse **yalnızca
/// görseldir**: satırın tamamı dokunulabilir olduğunda satır semantics'i taşır, daire taşımaz.
class AppCheckCircle extends StatelessWidget {
  const AppCheckCircle({
    super.key,
    required this.selected,
    this.onChanged,
    this.semanticLabel,
  }) : assert(onChanged == null || semanticLabel != null);

  final bool selected;
  final ValueChanged<bool>? onChanged;

  /// [onChanged] verildiğinde zorunlu.
  final String? semanticLabel;

  static const double size = 24;

  @override
  Widget build(BuildContext context) {
    final mark = AppSelectionMark(
      selected: selected,
      circle: true,
      enabled: true,
      size: size,
      iconSize: AppIconSize.s16,
    );
    if (onChanged == null) {
      return ExcludeSemantics(child: mark);
    }
    return AppPressable(
      onPressed: () {
        AppHaptics.selection();
        onChanged!(!selected);
      },
      semanticLabel: semanticLabel!,
      semanticChecked: selected,
      scaleOnPress: false,
      focusShape: const CircleBorder(),
      builder: (context, pressed) => SizedBox.square(
        dimension: AppSpacing.touchTarget,
        child: Center(child: mark),
      ),
    );
  }
}
