import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../app/app_router.dart';
import '../../app/app_scope.dart';
import '../../core/data/auth_repository.dart';
import '../../core/design_system/components/agreement/agreement_arc.dart';
import '../../core/design_system/components/brand/app_logo.dart';
import '../../core/design_system/components/buttons/app_button.dart';
import '../../core/design_system/components/deck/deck_card.dart';
import '../../core/design_system/components/deck/deck_decision_overlay.dart';
import '../../core/design_system/components/deck/swipe_deck_physics.dart';
import '../../core/design_system/components/feedback/app_toast.dart';
import '../../core/design_system/components/people/app_avatar.dart';
import '../../core/design_system/foundations/app_icons.dart';
import '../../core/design_system/foundations/app_pressable.dart';
import '../../core/design_system/foundations/clamped_text_scale.dart';
import '../../core/design_system/foundations/context_extensions.dart';
import '../../core/design_system/gallery/design_system_gallery.dart';
import '../../core/design_system/tokens/app_fixed_colors.dart';
import '../../core/design_system/tokens/app_motion.dart';
import '../../core/design_system/tokens/app_radius.dart';
import '../../core/design_system/tokens/app_spacing.dart';
import '../../core/design_system/tokens/app_typography.dart';
import '../../l10n/app_localizations.dart';

/// A2 · Karşılama (SCREENS A2): tek ekran, üç sahne, bir kez oynayıp üçüncüde durur.
///
/// | Sahne | Süre | İçerik |
/// |---|---|---|
/// | 1 Marka | 0–2,5 sn | büyük iA işareti + "iAgree" + slogan |
/// | Geçiş | ~0,4 sn | büyük marka kaybolur, sol üstte küçük marka belirir |
/// | 2 Mekanizma | 2,5–5,5 sn | öndeki kart sağa kayar, "Olur" etiketi, uyum %80'e dolar |
/// | 3 Sosyal | 5,5–8,5 sn | avatarlar kenarlardan gelir, kesik çizgiler çizilir, ✓ belirir |
///
/// Butonlar ilk kareden itibaren görünür ve dokunulabilir; döngü, "Atla" ve haptic yoktur.
/// Reduce Motion'da doğrudan son sahne. Tek `AnimationController` ve `Interval`'lar kullanılır:
/// sahneler zamansal olarak birbirine bağlı, tek yerden okunur.
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key, this.animate = true});

  /// False ise son sahne doğrudan gösterilir (test, galeri).
  final bool animate;

  /// Animasyonun toplam süresi.
  static const Duration duration = Duration(milliseconds: 8500);

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  // Zaman çizelgesi (ms).
  static const double _total = 8500;
  static const double _transitionStart = 2500;
  static const double _transitionEnd = 2900;
  static const double _scene2InEnd = 3300;
  static const double _slideStart = 3500;
  static const double _slideEnd = 4300;
  static const double _badgeStart = 4100;
  static const double _badgeEnd = 4900;
  static const double _scene3Start = 5500;
  static const double _scene3End = 5900;
  static const double _avatarsEnd = 6700;
  static const double _linesEnd = 7300;
  static const double _checkStart = 7200;
  static const double _checkEnd = 8200;

  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: WelcomeScreen.duration,
  );
  final List<CurvedAnimation> _curves = [];

  late Animation<double> _transition;
  late Animation<double> _scene2In;
  late Animation<double> _slide;
  late Animation<double> _badge;
  late Animation<double> _scene2Out;
  late Animation<double> _scene3In;
  late Animation<double> _avatars;
  late Animation<double> _lines;
  late Animation<double> _check;
  bool _initialized = false;

  final ValueNotifier<SwipeFrame> _frame = ValueNotifier(SwipeFrame.rest);
  late final TapGestureRecognizer _terms = TapGestureRecognizer()
    ..onTap = _linkSoon;
  late final TapGestureRecognizer _privacy = TapGestureRecognizer()
    ..onTap = _linkSoon;

  /// Ön kartın kayma mesafesi ve eşik hesabı için kart boyutu.
  static const double _slideDistance = 80;
  static const double _frontWidth = 220;

  Animation<double> _iv(double a, double b, Curve curve) {
    final curved = CurvedAnimation(
      parent: _c,
      curve: Interval(a / _total, b / _total, curve: curve),
    );
    _curves.add(curved);
    return curved;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    final motion = context.motion;
    _transition = _iv(_transitionStart, _transitionEnd, AppMotion.move);
    _scene2In = _iv(_transitionEnd, _scene2InEnd, AppMotion.enter);
    _slide = _iv(_slideStart, _slideEnd, AppMotion.enter);
    _badge = _iv(_badgeStart, _badgeEnd, AppMotion.enter);
    _scene2Out = _iv(_scene3Start, _scene3End, AppMotion.move);
    _scene3In = _iv(_scene3Start, _scene3End, AppMotion.enter);
    _avatars = _iv(_scene3End, _avatarsEnd, SpringCurve(motion.springBouncy));
    _lines = _iv(_avatarsEnd, _linesEnd, AppMotion.enter);
    _check = _iv(_checkStart, _checkEnd, SpringCurve(motion.springBouncy));

    _c.addListener(_onTick);
    if (!widget.animate || motion.reduceMotion) {
      _c.value = 1; // doğrudan son sahne
    } else {
      _c.forward();
    }
  }

  @override
  void dispose() {
    for (final c in _curves) {
      c.dispose();
    }
    _c.dispose();
    _frame.dispose();
    _terms.dispose();
    _privacy.dispose();
    super.dispose();
  }

  /// Ön kartın "Olur" etiketi ve tonu, kayma ilerlemesine bağlıdır.
  void _onTick() {
    _frame.value = SwipePhysics.frame(
      Offset(_slideDistance * _slide.value, 0),
      const Size(_frontWidth, _frontWidth / DeckCard.aspectRatio),
    );
  }

  void _linkSoon() => AppToast.show(
    context,
    message: AppLocalizations.of(context).welcomeLinkSoon,
  );

  Future<void> _apple() async {
    final scope = AppScope.of(context);
    final outcome = await scope.auth.signInWithApple();
    if (!mounted) return;
    switch (outcome) {
      case NeedsProfile():
        AppRoutes.pushProfile(context, outcome);
      case SignedIn(:final user):
        AppRoutes.finishSignIn(context, user);
      case WrongCode():
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = context.colors;

    return Scaffold(
      backgroundColor: c.canvas,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenPadding,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSpacing.sm),
              // Sol üstte küçük marka; geçişte belirir. Debug'da uzun basınca galeri.
              GestureDetector(
                onLongPress: kDebugMode
                    ? () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const DesignSystemGallery(),
                        ),
                      )
                    : null,
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: FadeTransition(
                    opacity: _transition,
                    child: const AppLogo.auto(size: _smallLogo, wordmark: true),
                  ),
                ),
              ),
              Expanded(child: _stage(context)),
              const SizedBox(height: AppSpacing.md),
              _AppleButton(label: l10n.welcomeApple, onPressed: _apple),
              const SizedBox(height: AppSpacing.sm),
              AppButton.secondary(
                label: l10n.welcomeEmail,
                icon: AppIcons.mail,
                onPressed: () => AppRoutes.pushEmail(context),
              ),
              const SizedBox(height: AppSpacing.sm),
              _termsText(context),
              const SizedBox(height: AppSpacing.xs),
            ],
          ),
        ),
      ),
    );
  }

  static const double _smallLogo = 34;
  static const double _bigLogo = 104;

  /// Sahneler birbirinin üstünde, aynı alanda.
  Widget _stage(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Stack(
      children: [
        // Sahne 1: marka. Geçişte solar ve sol üste doğru küçülür.
        Positioned.fill(
          child: AnimatedBuilder(
            animation: _transition,
            builder: (context, child) {
              final t = _transition.value;
              if (t >= 1) return const SizedBox.shrink();
              return Opacity(
                opacity: 1 - t,
                child: Transform.translate(
                  offset: Offset(-_shiftX * t, -_shiftY * t),
                  child: Transform.scale(
                    alignment: Alignment.bottomLeft,
                    scale: 1 - _shrink * t,
                    child: child,
                  ),
                ),
              );
            },
            child: _sceneOne(context),
          ),
        ),
        // Sahne 2: mekanizma.
        Positioned.fill(
          child: _SceneFade(
            inAnimation: _scene2In,
            outAnimation: _scene2Out,
            child: _Scene(
              visual: _MechanismVisual(
                slide: _slide,
                badge: _badge,
                frame: _frame,
                slideDistance: _slideDistance,
                frontWidth: _frontWidth,
              ),
              title: l10n.welcomeSceneTwoTitle,
              body: l10n.welcomeSceneTwoBody,
            ),
          ),
        ),
        // Sahne 3: sosyal. Son durak.
        Positioned.fill(
          child: _SceneFade(
            inAnimation: _scene3In,
            child: _Scene(
              visual: _SocialVisual(
                avatars: _avatars,
                lines: _lines,
                check: _check,
              ),
              title: l10n.welcomeSceneThreeTitle,
              body: l10n.welcomeSceneThreeBody,
            ),
          ),
        ),
      ],
    );
  }

  static const double _shiftX = AppSpacing.xl;
  static const double _shiftY = AppSpacing.giant;
  static const double _shrink = 0.5;

  Widget _sceneOne(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = context.colors;
    final text = context.text;
    final block = Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.giant),
      child: Semantics(
        header: true,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AppLogo.auto(size: _bigLogo),
            const SizedBox(height: AppSpacing.md),
            ClampedTextScale.display(
              child: Text(
                'iAgree',
                textScaler: TextScaler.noScaling,
                style: AppTypography.regular.hero.copyWith(
                  color: c.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: _taglineWidth),
              child: Text(
                l10n.welcomeTagline,
                style: text.lead.copyWith(color: c.textSecondary),
              ),
            ),
          ],
        ),
      ),
    );
    // Büyük yazı boyutunda blok alana sığmazsa alttan hizalı kayar (sahne 2,5 sn'de kaybolur).
    return LayoutBuilder(
      builder: (context, box) => SingleChildScrollView(
        reverse: true,
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: box.maxHeight),
          child: Align(
            alignment: AlignmentDirectional.bottomStart,
            child: block,
          ),
        ),
      ),
    );
  }

  static const double _taglineWidth = 300;

  Widget _termsText(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = context.colors;
    final style = context.text.caption.copyWith(color: c.textTertiary);
    final link = style.copyWith(color: c.brand, fontWeight: FontWeight.w600);
    final full = l10n.welcomeTerms('\u0001', '\u0002');
    final parts = <InlineSpan>[];
    var rest = full;
    while (rest.isNotEmpty) {
      final a = rest.indexOf('\u0001');
      final b = rest.indexOf('\u0002');
      final next = [a, b].where((i) => i >= 0).fold<int>(rest.length, math.min);
      if (next > 0) parts.add(TextSpan(text: rest.substring(0, next)));
      if (next == rest.length) break;
      final isTerms = rest[next] == '\u0001';
      parts.add(
        TextSpan(
          text: isTerms ? l10n.welcomeTermsLabel : l10n.welcomePrivacyLabel,
          style: link,
          recognizer: isTerms ? _terms : _privacy,
        ),
      );
      rest = rest.substring(next + 1);
    }
    return Text.rich(
      TextSpan(children: parts),
      textAlign: TextAlign.center,
      style: style,
    );
  }
}

/// Bir sahnenin giriş/çıkış solması.
class _SceneFade extends StatelessWidget {
  const _SceneFade({
    required this.inAnimation,
    required this.child,
    this.outAnimation,
  });

  final Animation<double> inAnimation;
  final Animation<double>? outAnimation;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([inAnimation, ?outAnimation]),
      child: child,
      builder: (context, c) {
        final v = inAnimation.value * (1 - (outAnimation?.value ?? 0));
        return IgnorePointer(
          child: Opacity(opacity: v.clamp(0.0, 1.0), child: c),
        );
      },
    );
  }
}

/// Sahne düzeni: üstte görsel (dar ekranda küçülür), altta `display` başlık + açıklama.
class _Scene extends StatelessWidget {
  const _Scene({required this.visual, required this.title, required this.body});

  final Widget visual;
  final String title;
  final String body;

  static const double _visualWidth = 350;
  static const double _visualHeight = 372;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = context.text;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md),
      child: LayoutBuilder(
        builder: (context, box) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ExcludeSemantics(
                child: Align(
                  alignment: Alignment.topCenter,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: SizedBox(
                      width: _visualWidth,
                      height: _visualHeight,
                      child: visual,
                    ),
                  ),
                ),
              ),
            ),
            // Büyük yazı boyutunda metin alanı sınırlanır ve kayar; görsel küçülür.
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: box.maxHeight * _maxTextShare,
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Semantics(
                      header: true,
                      child: ClampedTextScale.display(
                        child: Text(title, style: text.display),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      body,
                      style: text.body.copyWith(color: c.textSecondary),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }

  static const double _maxTextShare = 0.6;
}

/// Sahne 2: iki dönük kart; öndeki sağa kayar, "Olur" etiketi çıkar, uyum rozeti dolar.
class _MechanismVisual extends StatelessWidget {
  const _MechanismVisual({
    required this.slide,
    required this.badge,
    required this.frame,
    required this.slideDistance,
    required this.frontWidth,
  });

  final Animation<double> slide;
  final Animation<double> badge;
  final ValueListenable<SwipeFrame> frame;
  final double slideDistance;
  final double frontWidth;

  static const double _backLeft = 44;
  static const double _backTop = 28;
  static const double _backWidth = 210;
  static const double _backTurn = -7;
  static const double _frontLeft = 116;
  static const double _frontTop = 8;
  static const double _frontTurn = 5;
  static const double _slideTurn = 6;
  static const double _badgeLeft = 20;
  static const double _badgeTop = 286;

  double _rad(double degrees) => degrees * math.pi / 180;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          left: _backLeft,
          top: _backTop,
          width: _backWidth,
          child: Transform.rotate(
            angle: _rad(_backTurn),
            child: DeckCard.place(
              name: 'Mavi Kapı Kahve',
              photos: [ColoredBox(color: c.avatarTints[4])],
              rating: 4.7,
              category: 'Kahve',
              priceLevel: 1,
              distanceKm: 0.65,
            ),
          ),
        ),
        Positioned(
          left: _frontLeft,
          top: _frontTop,
          width: frontWidth,
          child: AnimatedBuilder(
            animation: slide,
            builder: (context, child) => Transform.translate(
              offset: Offset(slideDistance * slide.value, 0),
              child: Transform.rotate(
                angle: _rad(_frontTurn + _slideTurn * slide.value),
                child: child,
              ),
            ),
            child: DeckCardScope(
              frame: frame,
              child: DeckCard.place(
                name: 'Trattoria Lume',
                photos: const [
                  ColoredBox(color: AppFixedColors.inverseSurface),
                ],
                rating: 4.6,
                category: 'İtalyan',
                priceLevel: 2,
                distanceKm: 1.2,
              ),
            ),
          ),
        ),
        Positioned(
          left: _badgeLeft,
          top: _badgeTop,
          child: DecoratedBox(
            decoration: AppRadius.decoration(
              radius: AppRadius.lg,
              color: c.surface,
              elevation: context.elevation.e2,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AgreementArc(
                    loveCount: 2,
                    okCount: 2,
                    total: 5,
                    size: AgreementArcSize.small,
                    reveal: badge,
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    '4/5',
                    style: context.text.caption.tabular.copyWith(
                      color: c.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Sahne 3: ortada ✓, çevresinde beş avatar ve kesik çizgiler.
class _SocialVisual extends StatelessWidget {
  const _SocialVisual({
    required this.avatars,
    required this.lines,
    required this.check,
  });

  final Animation<double> avatars;
  final Animation<double> lines;
  final Animation<double> check;

  static const Offset _center = Offset(175, 170);
  static const double _bubble = 88;
  static const double _bubbleRing = 8;
  static const double _avatarOuter = 64;
  static const double _avatarRing = 2;
  static const double _fromEdge = 260;

  /// Avatar merkezleri (tasarım alanında) ve adları.
  static const List<(Offset, String)> _nodes = [
    (Offset(175, 60), 'Ayşe Yılmaz'),
    (Offset(289, 133), 'Can Kaya'),
    (Offset(245, 267), 'Deniz Er'),
    (Offset(105, 267), 'Mert Zor'),
    (Offset(61, 133), 'Zeynep Bal'),
  ];

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(
          child: AnimatedBuilder(
            animation: lines,
            builder: (context, _) => CustomPaint(
              painter: _DashedLinesPainter(
                center: _center,
                targets: [for (final n in _nodes) n.$1],
                progress: lines.value.clamp(0.0, 1.0),
                color: c.borderControl,
              ),
            ),
          ),
        ),
        for (var i = 0; i < _nodes.length; i++)
          Positioned(
            left: _nodes[i].$1.dx - _avatarOuter / 2,
            top: _nodes[i].$1.dy - _avatarOuter / 2,
            child: AnimatedBuilder(
              animation: avatars,
              builder: (context, child) {
                final t = avatars.value;
                final dir = _nodes[i].$1 - _center;
                final away = dir / dir.distance * _fromEdge * (1 - t);
                return Opacity(
                  opacity: t.clamp(0.0, 1.0),
                  child: Transform.translate(offset: away, child: child),
                );
              },
              child: DecoratedBox(
                decoration: AppRadius.circle(
                  side: BorderSide(color: c.brand, width: _avatarRing),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(_avatarRing),
                  child: AppAvatar(
                    userId: _nodes[i].$2,
                    name: _nodes[i].$2,
                    size: AppAvatarSize.lg,
                  ),
                ),
              ),
            ),
          ),
        Positioned(
          left: _center.dx - _bubble / 2,
          top: _center.dy - _bubble / 2,
          child: AnimatedBuilder(
            animation: check,
            builder: (context, child) => Transform.scale(
              scale: check.value.clamp(0.0, 1.3),
              child: Opacity(
                opacity: check.value.clamp(0.0, 1.0),
                child: child,
              ),
            ),
            child: DecoratedBox(
              decoration: AppRadius.circle(
                color: c.brand,
                side: BorderSide(color: c.canvas, width: _bubbleRing),
              ),
              child: SizedBox.square(
                dimension: _bubble,
                child: Icon(
                  AppIcons.check,
                  size: AppIconSize.s32,
                  color: c.onBrand,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Merkezden her avatara kesik çizgiler çizer; [progress] kadarı görünür.
class _DashedLinesPainter extends CustomPainter {
  const _DashedLinesPainter({
    required this.center,
    required this.targets,
    required this.progress,
    required this.color,
  });

  final Offset center;
  final List<Offset> targets;
  final double progress;
  final Color color;

  static const double _stroke = 1.5;
  static const double _dash = 3;
  static const double _gap = 5;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;
    final paint = Paint()
      ..color = color
      ..strokeWidth = _stroke
      ..strokeCap = StrokeCap.round;
    for (final t in targets) {
      final length = (t - center).distance * progress;
      final dir = (t - center) / (t - center).distance;
      for (var d = 0.0; d < length; d += _dash + _gap) {
        final end = math.min(d + _dash, length);
        canvas.drawLine(center + dir * d, center + dir * end, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DashedLinesPainter old) =>
      old.progress != progress || old.color != color;
}

/// "Apple ile devam et": ışık temada siyah, koyu temada beyaz pill. Gerçek "Sign in with
/// Apple" butonu paketle gelene kadar yer tutucu.
class _AppleButton extends StatelessWidget {
  const _AppleButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  static const double _height = 52;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return AppPressable(
      onPressed: onPressed,
      semanticLabel: label,
      minWidth: double.infinity,
      builder: (context, pressed) => DecoratedBox(
        decoration: AppRadius.decoration(
          radius: AppRadius.pill,
          color: c.textPrimary,
        ),
        child: SizedBox(
          height: _height,
          child: Center(
            child: Text(
              label,
              style: context.text.button.copyWith(color: c.canvas),
            ),
          ),
        ),
      ),
    );
  }
}
