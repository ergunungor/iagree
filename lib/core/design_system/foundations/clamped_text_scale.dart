import 'package:flutter/widgets.dart';

import '../tokens/app_typography.dart';

/// Dynamic Type ölçeğini altındaki metinler için sınırlar.
class ClampedTextScale extends StatelessWidget {
  const ClampedTextScale({
    super.key,
    required this.maxScaleFactor,
    required this.child,
  });

  /// display ve h1 (en fazla 1.3x).
  const ClampedTextScale.display({super.key, required this.child})
    : maxScaleFactor = AppTypography.displayMaxScale;

  /// AgreementArc içindeki sayı (en fazla 1.5x).
  const ClampedTextScale.arcNumber({super.key, required this.child})
    : maxScaleFactor = AppTypography.arcNumberMaxScale;

  final double maxScaleFactor;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: maxScaleFactor,
      child: child,
    );
  }
}
