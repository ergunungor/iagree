import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

import '../../foundations/context_extensions.dart';
import '../../tokens/app_motion.dart';
import '../../tokens/app_radius.dart';

/// Akış ilerlemesi (DESIGN_SYSTEM.md §10 "Navigation"): nav bar altında 4px çubuk.
///
/// "Adım 2/4" yazılmaz; ilerleme yalnızca çubukla ve VoiceOver değeriyle (`%50`) anlatılır.
/// Değişim `AppMotion` ile akar, Reduce Motion'da anında olur.
class AppFlowProgress extends StatelessWidget {
  const AppFlowProgress({super.key, required this.value, this.rounded = false})
    : assert(value >= 0 && value <= 1);

  /// 0–1 arası ilerleme.
  final double value;

  /// İz de pill olur (deste üst barı gibi satır içi kullanım); varsayılan düz çubuktur.
  final bool rounded;

  static const double height = 4;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final motion = context.motion;
    final percent = NumberFormat.percentPattern(
      Localizations.localeOf(context).toLanguageTag(),
    ).format(value);

    final bar = ColoredBox(
      color: c.surfaceMuted,
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(end: value),
        duration: motion.standard,
        curve: AppMotion.move,
        builder: (context, v, _) => Align(
          alignment: AlignmentDirectional.centerStart,
          child: FractionallySizedBox(
            widthFactor: v,
            heightFactor: 1,
            child: DecoratedBox(
              decoration: AppRadius.decoration(
                radius: AppRadius.pill,
                color: c.brand,
              ),
            ),
          ),
        ),
      ),
    );

    return Semantics(
      value: percent,
      child: ExcludeSemantics(
        child: SizedBox(
          height: height,
          child: rounded
              ? ClipPath(
                  clipper: ShapeBorderClipper(
                    shape: AppRadius.border(AppRadius.pill),
                  ),
                  child: bar,
                )
              : bar,
        ),
      ),
    );
  }
}
