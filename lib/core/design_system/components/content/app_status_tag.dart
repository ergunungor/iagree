import 'package:flutter/material.dart';

import '../../foundations/context_extensions.dart';
import '../../tokens/app_radius.dart';
import '../../tokens/app_spacing.dart';

/// Liste satırı sağındaki durum etiketi (SCREENS C1 "Sıra sende"): soft seçili stil, yani
/// `brandSoft` zemin, `onBrandSoft` metin ve 1,5px `brand` kenar. Dokunulmaz; satırın
/// VoiceOver etiketi durumu zaten taşır, bu yüzden kendi Semantics'i yoktur.
class AppStatusTag extends StatelessWidget {
  const AppStatusTag({super.key, required this.label});

  final String label;

  static const double _minHeight = 28;
  static const double _border = 1.5;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return ExcludeSemantics(
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: _minHeight),
        child: DecoratedBox(
          decoration: AppRadius.decoration(
            radius: AppRadius.pill,
            color: c.brandSoft,
            side: BorderSide(color: c.brand, width: _border),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xxs / 2,
            ),
            child: Center(
              widthFactor: 1,
              child: Text(
                label,
                style: context.text.caption.copyWith(
                  color: c.onBrandSoft,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
