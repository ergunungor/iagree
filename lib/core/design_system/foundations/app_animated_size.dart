import 'package:flutter/widgets.dart';

/// `AnimatedSize`'ın Reduce Motion'da güvenli hâli.
///
/// Süre 0 ise `AnimatedSize` layout sırasında kendini yeniden işaretleyip çöker; bu yüzden
/// süre sıfırken animasyonsuz, çocuğu doğrudan döndürür.
class AppAnimatedSize extends StatelessWidget {
  const AppAnimatedSize({
    super.key,
    required this.duration,
    required this.curve,
    required this.child,
    this.alignment = Alignment.center,
  });

  final Duration duration;
  final Curve curve;
  final AlignmentGeometry alignment;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (duration == Duration.zero) return child;
    return AnimatedSize(
      duration: duration,
      curve: curve,
      alignment: alignment,
      child: child,
    );
  }
}
