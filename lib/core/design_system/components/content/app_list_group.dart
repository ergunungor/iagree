import 'package:flutter/material.dart';

import '../../foundations/app_icons.dart';
import '../../foundations/app_pressable.dart';
import '../../foundations/context_extensions.dart';
import '../../tokens/app_motion.dart';
import '../../tokens/app_radius.dart';
import '../../tokens/app_spacing.dart';
import '../../tokens/app_typography.dart';

/// iOS "inset grouped" liste grubu (DESIGN_SYSTEM.md §10 "ListGroup"): `surface`, `radius lg`,
/// E0 (gölge yok). Satırlar [AppListRow]'dur; ayırıcılar metnin başladığı yerden başlar.
/// Increase Contrast açıkken `border` kenarı.
class AppListGroup extends StatelessWidget {
  const AppListGroup({super.key, required this.children});

  final List<AppListRow> children;

  static const double _hairline = 1;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final highContrast = MediaQuery.highContrastOf(context);
    return DecoratedBox(
      decoration: AppRadius.decoration(
        radius: AppRadius.lg,
        color: c.surface,
        side: highContrast
            ? BorderSide(color: c.borderControl, width: _hairline)
            : null,
      ),
      child: ClipPath(
        clipper: ShapeBorderClipper(shape: AppRadius.border(AppRadius.lg)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < children.length; i++)
              _RowScope(isLast: i == children.length - 1, child: children[i]),
          ],
        ),
      ),
    );
  }
}

class _RowScope extends InheritedWidget {
  const _RowScope({required this.isLast, required super.child});

  final bool isLast;

  static bool isLastOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_RowScope>()?.isLast ?? true;

  @override
  bool updateShouldNotify(_RowScope old) => isLast != old.isLast;
}

/// [AppListGroup] satırı: min 52, dikey padding 12, yatay 16.
///
/// Tek satır metin hedeflenir; durum görsel öğeyle (trailing) anlatılır. [onPressed] verilirse
/// satır dokunulabilir (basınca `surfacePressed`) ve tek öğe olarak okunur. [selected] verilirse
/// tekli seçim satırıdır: seçiliyse sağda `brand` ✓ (radio yok).
class AppListRow extends StatelessWidget {
  const AppListRow({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.leadingExtent,
    this.trailing,
    this.showsChevron = false,
    this.selected,
    this.emphasized = false,
    this.destructive = false,
    this.onPressed,
  }) : assert(
         (leading == null) == (leadingExtent == null),
         'leading verilirse genişliği leadingExtent ile bildirilmeli: ayırıcı metnin '
         'başladığı yerden başlar.',
       );

  /// Ana metin; `body` (ya da [emphasized] ise `title`) stili.
  final String title;

  /// Meta satırı (`caption`, `textSecondary`).
  final String? subtitle;

  /// Solda sabit boyutlu öğe (ikon, avatar, thumbnail).
  final Widget? leading;

  /// [leading]'in genişliği.
  final double? leadingExtent;

  /// Sağdaki öğe (durum etiketi, toggle, Arc...).
  final Widget? trailing;

  /// Sağda ince chevron (gezinti satırı).
  final bool showsChevron;

  /// Null: seçim satırı değil. Doğru/yanlış: tekli seçim satırı; seçiliyse sağda ✓.
  final bool? selected;

  /// Liste başlığı ağırlığında (`title`, 600) ana metin.
  final bool emphasized;

  /// Yıkıcı eylem satırı: ana metin `error`.
  final bool destructive;

  final VoidCallback? onPressed;

  static const double _minHeight = 52;
  static const double _hairline = 1;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final motion = context.motion;
    final text = context.text;
    final isLast = _RowScope.isLastOf(context);
    final inset =
        AppSpacing.md + (leading == null ? 0 : leadingExtent! + AppSpacing.sm);
    final interactive = onPressed != null;

    final titleColor = destructive ? c.error : c.textPrimary;

    Widget row(bool pressed) {
      return AnimatedContainer(
        duration: motion.fast,
        curve: AppMotion.move,
        color: pressed ? c.surfacePressed : Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(minHeight: _minHeight),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                child: Row(
                  children: [
                    if (leading != null) ...[
                      SizedBox(width: leadingExtent, child: leading),
                      const SizedBox(width: AppSpacing.sm),
                    ],
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            title,
                            style: (emphasized ? text.title : text.body)
                                .copyWith(color: titleColor),
                          ),
                          if (subtitle != null)
                            Text(
                              subtitle!,
                              style: text.caption.tabular.copyWith(
                                color: c.textSecondary,
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (trailing != null) ...[
                      const SizedBox(width: AppSpacing.sm),
                      trailing!,
                    ],
                    if (selected != null) ...[
                      const SizedBox(width: AppSpacing.sm),
                      // Seçili değilken de yer ayrılır: seçim değişince metin kaymaz.
                      SizedBox.square(
                        dimension: AppIconSize.s20,
                        child: selected!
                            ? Icon(
                                AppIcons.check,
                                size: AppIconSize.s20,
                                color: c.brand,
                              )
                            : null,
                      ),
                    ],
                    if (showsChevron) ...[
                      const SizedBox(width: AppSpacing.xs),
                      Icon(
                        AppIcons.chevronRight,
                        size: AppIconSize.s20,
                        color: c.textTertiary,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            if (!isLast)
              Padding(
                padding: EdgeInsets.only(left: inset),
                child: SizedBox(
                  height: _hairline,
                  child: ColoredBox(color: c.border),
                ),
              ),
          ],
        ),
      );
    }

    if (!interactive) return row(false);

    return AppPressable(
      onPressed: onPressed,
      semanticLabel: title,
      semanticValue: subtitle,
      semanticSelected: selected,
      scaleOnPress: false,
      focusShape: AppRadius.border(AppRadius.lg),
      minWidth: double.infinity,
      builder: (context, pressed) => row(pressed),
    );
  }
}
