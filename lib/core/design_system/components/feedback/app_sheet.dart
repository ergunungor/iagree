import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../foundations/app_icons.dart';
import '../../foundations/context_extensions.dart';
import '../../tokens/app_motion.dart';
import '../../tokens/app_radius.dart';
import '../../tokens/app_spacing.dart';
import '../buttons/app_icon_button.dart';

/// Sheet yüksekliği (detent).
enum AppSheetDetent {
  /// İçeriğe sığar.
  fit,

  /// Ekranın yaklaşık yarısı.
  medium,

  /// Neredeyse tam ekran.
  large,
}

/// Bottom sheet (DESIGN_SYSTEM.md §10 "Bottom Sheet").
///
/// `surfaceRaised`, üst köşeler `radius xl`, E3 + scrim, 36×5 grabber, yanlar 24, başlık `h3`
/// sola hizalı, CTA ([footer]) altta sabit. Kapatma: aşağı kaydırma ya da scrim; ✕ yalnızca
/// Large'da. **Üst üste en fazla bir sheet** açılır. İki adımdan uzun akış sheet'te yaşamaz.
abstract final class AppSheet {
  static bool _open = false;

  /// Açık sheet'in Navigator'ı. Navigator sökülmüşse (uygulama yeniden kurulduysa) sheet
  /// "kapalı" sayılır; bayrak takılı kalmaz.
  static NavigatorState? _owner;

  /// Şu an bir sheet açık mı.
  static bool get isOpen => _open && (_owner?.mounted ?? false);

  static const double _grabberWidth = 36;
  static const double _grabberHeight = 5;
  static const double _fitMaxFraction = 0.9;
  static const double _mediumFraction = 0.5;

  /// Bunun altındaki yüksekliklerde (kapanış animasyonunun sonu) içerik çizilmez.
  static const double _minContentHeight = 120;

  /// Large detent'in ekran üstünden bırakacağı boşluk (safe area üstüne eklenir).
  static const double _largeTopGap = AppSpacing.md;

  /// Sheet'i açar. Zaten bir sheet açıksa yenisini açmaz ve `null` döner.
  ///
  /// [detents]: `[fit]`, `[medium]`, `[large]` ya da sürüklenebilir `[medium, large]`.
  static Future<T?> show<T>(
    BuildContext context, {
    required String title,
    required WidgetBuilder builder,
    Widget? footer,
    List<AppSheetDetent> detents = const [AppSheetDetent.fit],
  }) {
    assert(
      detents.length == 1 ||
          (detents.length == 2 &&
              detents[0] == AppSheetDetent.medium &&
              detents[1] == AppSheetDetent.large),
      'En fazla iki detent: yalnızca [medium, large] birlikte kullanılabilir.',
    );
    if (isOpen) return Future<T?>.value();
    _open = true;
    _owner = Navigator.of(context);

    final motion = AppMotion.of(context);
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      useSafeArea: false,
      backgroundColor: Colors.transparent,
      elevation: 0,
      barrierColor: colors.scrim,
      barrierLabel: l10n.commonClose,
      // Dokunarak ve aşağı kaydırarak kapanır; çoklu detent'te sürükleme yüksekliği değiştirir.
      enableDrag: detents.length == 1,
      sheetAnimationStyle: AnimationStyle(
        duration: motion.springStandardDuration,
        reverseDuration: motion.exitOf(motion.springStandardDuration),
        curve: motion.springStandardCurve,
        reverseCurve: AppMotion.exit,
      ),
      builder: (sheetContext) => _SheetBody(
        title: title,
        detents: detents,
        footer: footer,
        builder: builder,
      ),
    ).whenComplete(() {
      _open = false;
      _owner = null;
    });
  }
}

class _SheetBody extends StatefulWidget {
  const _SheetBody({
    required this.title,
    required this.detents,
    required this.builder,
    this.footer,
  });

  final String title;
  final List<AppSheetDetent> detents;
  final WidgetBuilder builder;
  final Widget? footer;

  @override
  State<_SheetBody> createState() => _SheetBodyState();
}

class _SheetBodyState extends State<_SheetBody> {
  bool _atLargest = false;

  bool get _multi => widget.detents.length == 2;

  double _fraction(BuildContext context, AppSheetDetent d) {
    final size = MediaQuery.sizeOf(context);
    switch (d) {
      case AppSheetDetent.medium:
        return AppSheet._mediumFraction;
      case AppSheetDetent.large:
        return 1 -
            (MediaQuery.paddingOf(context).top + AppSheet._largeTopGap) /
                size.height;
      case AppSheetDetent.fit:
        return AppSheet._fitMaxFraction;
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    if (_multi) {
      final medium = _fraction(context, AppSheetDetent.medium);
      final large = _fraction(context, AppSheetDetent.large);
      return NotificationListener<DraggableScrollableNotification>(
        onNotification: (n) {
          final atLargest = n.extent >= n.maxExtent - 0.01;
          if (atLargest != _atLargest) setState(() => _atLargest = atLargest);
          return false;
        },
        child: DraggableScrollableSheet(
          expand: false,
          initialChildSize: medium,
          // Aşağı sürüklenince kapanabilsin diye taban 0; medium ve large'a oturur (snap).
          minChildSize: 0,
          maxChildSize: large,
          snap: true,
          snapSizes: [medium, large],
          builder: (context, scrollController) => _Panel(
            title: widget.title,
            showClose: _atLargest,
            footer: widget.footer,
            fixedHeight: true,
            scrollController: scrollController,
            child: widget.builder(context),
          ),
        ),
      );
    }

    final detent = widget.detents.single;
    final panel = _Panel(
      title: widget.title,
      showClose: detent == AppSheetDetent.large,
      footer: widget.footer,
      fixedHeight: detent != AppSheetDetent.fit,
      child: widget.builder(context),
    );
    final height = detent == AppSheetDetent.fit
        ? null
        : _fraction(context, detent) * size.height;
    // Hizalama ve konum BottomSheet'in kendi yerleşiminden gelir. Ekranı kaplayan bir kap
    // (Align/ColoredBox) BottomSheet'in Material'ini tam ekran yapıp scrim dokunuşlarını yutar.
    return ConstrainedBox(
      constraints: height == null
          ? BoxConstraints(maxHeight: AppSheet._fitMaxFraction * size.height)
          : BoxConstraints.tightFor(height: height),
      child: panel,
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({
    required this.title,
    required this.showClose,
    required this.child,
    required this.fixedHeight,
    this.footer,
    this.scrollController,
  });

  final String title;
  final bool showClose;
  final Widget child;
  final Widget? footer;
  final bool fixedHeight;
  final ScrollController? scrollController;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = AppLocalizations.of(context);
    final safeBottom = MediaQuery.of(context).padding.bottom;

    // Sürüklenebilir (çoklu detent) sheet'te grabber ve başlık kaydırılabilir alanın içindedir:
    // kullanıcı sheet'i tam da grabber'dan tutup sürükler.
    final headerInScroll = scrollController != null;

    final grabber = Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xs),
      child: Center(
        child: DecoratedBox(
          decoration: AppRadius.decoration(
            radius: AppRadius.pill,
            color: c.textTertiary.withValues(alpha: 0.3),
          ),
          child: const SizedBox(
            width: AppSheet._grabberWidth,
            height: AppSheet._grabberHeight,
          ),
        ),
      ),
    );

    // Başlık (+ yalnızca Large'da ✕).
    final titleRow = Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.md,
        AppSpacing.xl,
        AppSpacing.sm,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Semantics(
              header: true,
              child: Text(title, style: context.text.h3),
            ),
          ),
          if (showClose)
            AppIconButton.soft(
              icon: AppIcons.close,
              semanticLabel: l10n.commonClose,
              onPressed: () => Navigator.of(context).maybePop(),
            ),
        ],
      ),
    );

    final body = Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: child,
    );

    final scrolling = SingleChildScrollView(
      controller: scrollController,
      child: headerInScroll
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [grabber, titleRow, body],
            )
          : body,
    );

    return Semantics(
      scopesRoute: true,
      namesRoute: true,
      explicitChildNodes: true,
      label: title,
      child: DecoratedBox(
        decoration: ShapeDecoration(
          color: c.surfaceRaised,
          shape: AppRadius.topBorder(AppRadius.xl),
          shadows: context.elevation.e3.shadows,
        ),
        child: ClipPath(
          clipper: ShapeBorderClipper(shape: AppRadius.topBorder(AppRadius.xl)),
          // Sürükleyerek kapatırken sheet sıfır yüksekliğe iner; içerik sığmayınca çizilmez
          // (aksi hâlde Column taşma hatası verir).
          child: LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.hasBoundedHeight &&
                  constraints.maxHeight < AppSheet._minContentHeight) {
                return const SizedBox.expand();
              }
              return _content(
                context,
                grabber: grabber,
                titleRow: titleRow,
                scrolling: scrolling,
                safeBottom: safeBottom,
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _content(
    BuildContext context, {
    required Widget grabber,
    required Widget titleRow,
    required Widget scrolling,
    required double safeBottom,
  }) {
    final headerInScroll = scrollController != null;
    return Column(
      mainAxisSize: fixedHeight ? MainAxisSize.max : MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!headerInScroll) ...[grabber, titleRow],
        if (fixedHeight)
          Expanded(child: scrolling)
        else
          Flexible(child: scrolling),
        if (footer != null)
          Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.xl,
              AppSpacing.sm,
              AppSpacing.xl,
              safeBottom + AppSpacing.xs,
            ),
            child: footer,
          )
        else
          SizedBox(height: safeBottom + AppSpacing.xs),
      ],
    );
  }
}
