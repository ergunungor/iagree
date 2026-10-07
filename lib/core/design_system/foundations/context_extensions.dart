import 'package:flutter/material.dart';

import '../tokens/app_colors.dart';
import '../tokens/app_elevation.dart';
import '../tokens/app_motion.dart';
import '../tokens/app_typography.dart';

/// Design system token'larına `BuildContext` üzerinden erişim.
extension AppBuildContext on BuildContext {
  /// Tema renkleri; Increase Contrast açıksa yüksek kontrastlı varyant.
  AppColors get colors {
    final theme = Theme.of(this);
    if (MediaQuery.highContrastOf(this)) {
      return theme.brightness == Brightness.dark
          ? AppColors.darkHighContrast
          : AppColors.lightHighContrast;
    }
    return theme.extension<AppColors>()!;
  }

  /// Tipografi; Bold Text açıksa ağırlıkları +100.
  AppTypography get text => MediaQuery.boldTextOf(this)
      ? AppTypography.boldText
      : AppTypography.regular;

  /// Hareket token'ları; Reduce Motion açıksa süreler 0.
  AppMotion get motion => AppMotion.of(this);

  /// Temaya göre gölge/hairline seviyeleri.
  AppElevation get elevation => Theme.of(this).brightness == Brightness.dark
      ? AppElevation.dark
      : AppElevation.light;
}
