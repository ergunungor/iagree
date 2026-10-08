import 'dart:math' as math;

import 'package:flutter/cupertino.dart';

import '../../../../l10n/app_localizations.dart';
import '../../foundations/app_icons.dart';
import '../../foundations/clamped_text_scale.dart';
import '../../foundations/context_extensions.dart';
import '../../tokens/app_spacing.dart';
import '../buttons/app_icon_button.dart';
import 'app_flow_progress.dart';

/// Nav bar'ın sağındaki tek bir aksiyon (Plain ikon butonu, 24'lük ikon).
class AppNavBarAction {
  const AppNavBarAction({
    required this.icon,
    required this.semanticLabel,
    required this.onPressed,
  });

  final IconData icon;
  final String semanticLabel;
  final VoidCallback? onPressed;
}

/// En fazla kaç aksiyon (DESIGN_SYSTEM.md §10 "Navigation").
const int _maxActions = 2;

/// Çubuk arka planının opaklığı: blur'ün görünmesi için tam opak olmamalı.
const double _barOpacity = 0.85;

/// İkonun kenara hizalanması için çubuk iç boşluğu: ikon 24, dokunma alanı 44 olduğundan
/// ikonun kenar boşluğu `screenPadding` olsun diye alandan o kadar eksiği bırakılır.
const double _edgePadding =
    AppSpacing.screenPadding - (AppSpacing.touchTarget - AppIconSize.s24) / 2;

/// Geri chevron'u ya da ✕ + aksiyonlar, iki bar türünde de aynı.
Widget? _leading(
  BuildContext context, {
  VoidCallback? onBack,
  VoidCallback? onClose,
}) {
  final l10n = AppLocalizations.of(context);
  if (onBack != null) {
    return AppIconButton.plain(
      icon: AppIcons.back,
      semanticLabel: l10n.commonBack,
      onPressed: onBack,
    );
  }
  if (onClose != null) {
    return AppIconButton.plain(
      icon: AppIcons.close,
      semanticLabel: l10n.commonClose,
      onPressed: onClose,
    );
  }
  return null;
}

List<Widget> _actionButtons(List<AppNavBarAction> actions) => [
  for (final a in actions)
    AppIconButton.plain(
      icon: a.icon,
      semanticLabel: a.semanticLabel,
      onPressed: a.onPressed,
    ),
];

/// Kaydırılan sayfalar için nav bar (DESIGN_SYSTEM.md §10 "Navigation").
///
/// `CupertinoSliverNavigationBar` üzerine kuruludur: large title `h1` (Fraunces), kaydırınca
/// inline `title`'a (SF Pro) iner; içerik altından geçince blur + 1px `border` hairline belirir.
/// Geri yalnızca chevron, sağda en fazla 2 aksiyon. Tab bar yoktur. [progress] verilirse bar
/// altında 4px akış çubuğu görünür. `CustomScrollView.slivers`'ın ilk elemanı olarak kullanılır.
class AppNavBar extends StatelessWidget {
  const AppNavBar({
    super.key,
    required this.title,
    this.onBack,
    this.onClose,
    this.actions = const [],
    this.progress,
  }) : assert(onBack == null || onClose == null, 'Geri ve ✕ birlikte olmaz.'),
       assert(
         actions.length <= _maxActions,
         'En fazla $_maxActions aksiyon konabilir.',
       ),
       assert(progress == null || (progress >= 0 && progress <= 1));

  final String title;

  /// Verilirse solda geri chevron'u.
  final VoidCallback? onBack;

  /// Verilirse solda ✕ (tam ekran modal).
  final VoidCallback? onClose;

  final List<AppNavBarAction> actions;

  /// 0–1; verilirse bar altında akış çubuğu.
  final double? progress;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = context.text;
    final leading = _leading(context, onBack: onBack, onClose: onClose);

    // Cupertino, arka planı sayfa zemininden çubuk rengine kaydırmayla geçirir; zemin rengini
    // bu miras widget'tan okur. Scaffold Material olduğu için biz sağlarız.
    return CupertinoPageScaffoldBackgroundColor(
      color: c.canvas,
      child: CupertinoSliverNavigationBar(
        automaticallyImplyLeading: false,
        automaticallyImplyTitle: false,
        // Inline başlık yalnızca large title kayıp gidince görünür; yoksa başlık iki kez çıkar.
        alwaysShowMiddle: false,
        transitionBetweenRoutes: false,
        backgroundColor: c.canvas.withValues(alpha: _barOpacity),
        border: Border(bottom: BorderSide(color: c.border)),
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: _edgePadding,
        ),
        leading: leading,
        trailing: actions.isEmpty
            ? null
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: _actionButtons(actions),
              ),
        middle: Semantics(
          header: true,
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: text.title,
          ),
        ),
        largeTitle: Padding(
          // Cupertino büyük başlığı 16'dan başlatır; ekran kenar boşluğu 20.
          padding: const EdgeInsetsDirectional.only(
            start: AppSpacing.screenPadding - 16,
            end: AppSpacing.screenPadding,
          ),
          child: ClampedTextScale.display(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: text.h1,
            ),
          ),
        ),
        bottom: progress == null
            ? null
            : PreferredSize(
                preferredSize: const Size.fromHeight(AppFlowProgress.height),
                child: AppFlowProgress(value: progress!),
              ),
        bottomMode: progress == null ? null : NavigationBarBottomMode.always,
      ),
    );
  }
}

/// Kaydırılmayan ekranlar ve tam ekran modal'lar için sabit, küçük başlıklı nav bar.
///
/// Yerleşim [AppNavBar] ile aynı (geri/✕ solda, en fazla 2 aksiyon sağda), başlık ortalı `title`.
/// `Scaffold.appBar` olarak kullanılır. Sabit içerik üzerinde olduğundan blur yoktur;
/// [hairline] ile alt çizgi eklenebilir.
class AppInlineNavBar extends StatelessWidget implements PreferredSizeWidget {
  const AppInlineNavBar({
    super.key,
    required this.title,
    this.onBack,
    this.onClose,
    this.actions = const [],
    this.progress,
    this.hairline = false,
  }) : assert(onBack == null || onClose == null, 'Geri ve ✕ birlikte olmaz.'),
       assert(
         actions.length <= _maxActions,
         'En fazla $_maxActions aksiyon konabilir.',
       ),
       assert(progress == null || (progress >= 0 && progress <= 1));

  final String title;
  final VoidCallback? onBack;
  final VoidCallback? onClose;
  final List<AppNavBarAction> actions;
  final double? progress;
  final bool hairline;

  static const double _barHeight = AppSpacing.touchTarget;

  /// Safe area üstü dışarıda kalır; `build` onu kendisi ekler.
  @override
  Size get preferredSize => Size.fromHeight(
    _barHeight + (progress == null ? 0 : AppFlowProgress.height),
  );

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final leading = _leading(context, onBack: onBack, onClose: onClose);
    // Başlığın tam ortada kalması için iki yan aynı genişlikte.
    final slots = math.max(leading == null ? 0 : 1, actions.length);
    final side = slots * AppSpacing.touchTarget;

    return ColoredBox(
      color: c.canvas,
      child: SafeArea(
        bottom: false,
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: hairline
                ? Border(bottom: BorderSide(color: c.border))
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: _barHeight,
                child: Padding(
                  padding: const EdgeInsetsDirectional.symmetric(
                    horizontal: _edgePadding,
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: side,
                        child: Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: leading,
                        ),
                      ),
                      Expanded(
                        child: Semantics(
                          header: true,
                          child: Text(
                            title,
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: context.text.title,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: side,
                        child: Align(
                          alignment: AlignmentDirectional.centerEnd,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: _actionButtons(actions),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (progress != null) AppFlowProgress(value: progress!),
            ],
          ),
        ),
      ),
    );
  }
}
