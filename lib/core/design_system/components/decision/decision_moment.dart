import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';

import '../../../../l10n/app_localizations.dart';
import '../../foundations/app_haptics.dart';
import '../../foundations/app_icons.dart';
import '../../foundations/clamped_text_scale.dart';
import '../../foundations/context_extensions.dart';
import '../../tokens/app_fixed_colors.dart';
import '../../tokens/app_motion.dart';
import '../../tokens/app_radius.dart';
import '../../tokens/app_spacing.dart';
import '../../tokens/app_typography.dart';
import '../agreement/agreement_arc.dart';
import '../buttons/app_button.dart';
import '../buttons/app_icon_button.dart';
import '../content/place_meta.dart';
import '../people/app_avatar.dart';
import '../people/app_avatar_group.dart';
import '../result/result_card.dart' show resultThumb;

/// Karar anı: uygulamadaki tek tam ekran başarı anı (DESIGN_SYSTEM.md §10 "DecisionMoment",
/// SCREENS D8).
///
/// - [isUnanimous] (oybirliği, `DecisionA`): `momentBg` zemin, avatar kümesi, Arc L, "Hepiniz
///   anlaştınız.", mekan kartı, moment butonları. Koreografi 2 sn: zemin → avatarlar kenarlardan
///   merkeze (spring) → temas (halka dalgası + `medium` haptic) → Arc %100'e dolar (`success`
///   haptic) → başlık → mekan kartı → eylemler aktif.
/// - Çoğunluk (`DecisionB`): `canvas` zemin, mekan fotoğrafı, avatarlar fotoğraf kenarında,
///   "Karar verildi.", "3/4 oyla seçildi" etiketi. Avatarlar baştan yerinde, halka dalgası ve
///   Arc yok, yalnızca `light` haptic; kısa bir giriş.
///
/// Dokununca animasyon atlanır (haptic'siz). Reduce Motion açıkken hareket yoktur: içerik
/// kısa bir geçişle belirir.
class DecisionMoment extends StatefulWidget {
  const DecisionMoment({
    super.key,
    required this.isUnanimous,
    required this.participants,
    required this.placeName,
    required this.photo,
    required this.onDirections,
    required this.onShare,
    required this.onClose,
    this.meta = const PlaceMeta(),
    this.loveCount = 0,
    this.okCount = 0,
    this.total = 0,
    this.votes = 0,
    this.totalVotes = 0,
    this.animate = true,
  }) : assert(
         !isUnanimous || (total > 0 && loveCount + okCount == total),
         'Oybirliğinde herkes olumlu olmalı.',
       ),
       assert(isUnanimous || (totalVotes > 0 && votes <= totalVotes));

  final bool isUnanimous;

  /// Karara katılanlar; oda sahibi ilk. En fazla 5 avatar çizilir.
  final List<AppAvatarPerson> participants;

  final String placeName;

  /// Mekan fotoğrafı (kart thumbnail'i ve çoğunlukta büyük görsel).
  final Widget photo;

  final PlaceMeta meta;

  /// Oybirliği: Arc için "Çok isterim" ve "Olur" sayıları ve toplam kişi.
  final int loveCount;
  final int okCount;
  final int total;

  /// Çoğunluk: kazanan seçeneğin oyu ve toplam oy ("3/4 oyla seçildi").
  final int votes;
  final int totalVotes;

  /// Yol tarifi (Apple Maps), paylaş ve kapat; entegrasyon çağıranındır.
  final VoidCallback onDirections;
  final VoidCallback onShare;
  final VoidCallback onClose;

  /// False ise son kare doğrudan gösterilir (galeri, test).
  final bool animate;

  /// Oybirliği koreografisinin toplam süresi (tablo: aksiyonlar ≤ 2000 ms).
  static const Duration unanimousDuration = Duration(milliseconds: 2000);

  /// Çoğunluk girişinin süresi.
  static const Duration majorityDuration = Duration(milliseconds: 700);

  static const int maxAvatars = 5;

  @override
  State<DecisionMoment> createState() => _DecisionMomentState();
}

class _DecisionMomentState extends State<DecisionMoment>
    with SingleTickerProviderStateMixin {
  // Oybirliği koreografisi (ms) — DESIGN_SYSTEM.md §10 tablosu.
  static const double _total = 2000;
  static const double _bgEnd = 200;
  static const double _avatarsStart = 200;
  static const double _contact = 800;
  static const double _arcEnd = 1400;
  static const double _titleStart = 1400;
  static const double _titleEnd = 1700;
  static const double _cardStart = 1500;
  static const double _cardEnd = 1800;
  static const double _waveEnd = 1200;
  static const double _arcFadeStart = 700;

  static const double _titleRise = 8;
  static const double _cardRise = 80;

  late final AnimationController _c = AnimationController(vsync: this);
  final List<CurvedAnimation> _curves = [];

  late Animation<double> _bg;
  late Animation<double> _avatars;
  late Animation<double> _arcFade;
  late Animation<double> _wave;
  late Animation<double> _arcReveal;
  late Animation<double> _title;
  late Animation<double> _card;
  late Animation<double> _actions;
  late Animation<double> _info;
  late Animation<double> _tag;

  bool _reduce = false;
  bool _initialized = false;
  bool _firedContact = false;
  bool _firedSuccess = false;
  bool _firedLight = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    final motion = context.motion;
    _reduce = motion.reduceMotion;
    final unanimous = widget.isUnanimous;

    Animation<double> iv(double a, double b, Curve curve, double total) {
      final curved = CurvedAnimation(
        parent: _c,
        curve: Interval(a / total, b / total, curve: curve),
      );
      _curves.add(curved);
      return curved;
    }

    if (_reduce) {
      // Reduce Motion: her şey tek bir kısa geçişle (crossfade) belirir, hareket yok.
      _c.duration = AppMotion.regular.standard;
      _bg = _avatars = _arcFade = _arcReveal = _title = _card = _actions =
          _info = _tag = _c;
      _wave = const AlwaysStoppedAnimation<double>(1);
    } else if (unanimous) {
      _c.duration = DecisionMoment.unanimousDuration;
      _bg = iv(0, _bgEnd, AppMotion.move, _total);
      _avatars = iv(
        _avatarsStart,
        _contact,
        SpringCurve(motion.springBouncy),
        _total,
      );
      _arcFade = iv(_arcFadeStart, _contact, Curves.linear, _total);
      _wave = iv(_contact, _waveEnd, AppMotion.enter, _total);
      _arcReveal = iv(_contact, _arcEnd, AppMotion.enter, _total);
      _title = iv(_titleStart, _titleEnd, AppMotion.enter, _total);
      _card = iv(
        _cardStart,
        _cardEnd,
        SpringCurve(motion.springStandard),
        _total,
      );
      _actions = iv(_cardStart, _cardEnd, Curves.linear, _total);
      _info = _title;
      _tag = _title;
    } else {
      const t = 700.0;
      _c.duration = DecisionMoment.majorityDuration;
      _bg = const AlwaysStoppedAnimation<double>(1);
      _avatars = const AlwaysStoppedAnimation<double>(1);
      _arcFade = const AlwaysStoppedAnimation<double>(1);
      _wave = const AlwaysStoppedAnimation<double>(1);
      _arcReveal = const AlwaysStoppedAnimation<double>(1);
      _title = iv(0, 300, AppMotion.enter, t);
      _info = iv(100, 400, AppMotion.enter, t);
      _tag = iv(200, 500, AppMotion.enter, t);
      _card = _info;
      _actions = iv(400, 700, Curves.linear, t);
    }

    if (!widget.animate) {
      _c.value = 1;
      _firedContact = _firedSuccess = _firedLight = true;
      return;
    }
    _c.addListener(_onTick);
    _c.addStatusListener(_onStatus);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _onTick(); // t = 0 anındaki haptic'ler (çoğunluk, Reduce Motion)
      _c.forward();
    });
  }

  @override
  void dispose() {
    for (final c in _curves) {
      c.dispose();
    }
    _c.dispose();
    super.dispose();
  }

  void _onTick() {
    final ms = _c.value * _total;
    if (_reduce) {
      if (!_firedSuccess) {
        _firedSuccess = true;
        widget.isUnanimous ? AppHaptics.success() : AppHaptics.light();
      }
      return;
    }
    if (!widget.isUnanimous) {
      if (!_firedLight) {
        _firedLight = true;
        AppHaptics.light();
      }
      return;
    }
    if (!_firedContact && ms >= _contact) {
      _firedContact = true;
      AppHaptics.medium();
    }
    if (!_firedSuccess && ms >= _arcEnd) {
      _firedSuccess = true;
      AppHaptics.success();
    }
  }

  void _onStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed) return;
    if (!MediaQuery.accessibleNavigationOf(context)) return;
    final l10n = AppLocalizations.of(context);
    SemanticsService.sendAnnouncement(
      View.of(context),
      '${widget.isUnanimous ? l10n.decisionUnanimous : l10n.decisionMajority} '
      '${widget.placeName}',
      Directionality.of(context),
    );
  }

  /// Dokununca koreografi atlanır: son kare, haptic'siz.
  void _skip() {
    if (!_c.isAnimating) return;
    _firedContact = _firedSuccess = _firedLight = true;
    _c.value = 1;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final unanimous = widget.isUnanimous;
    final overlay = unanimous || dark
        ? SystemUiOverlayStyle.light
        : SystemUiOverlayStyle.dark;

    final content = unanimous ? _unanimous(context) : _majority(context);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlay,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: _skip,
        child: unanimous
            ? AnimatedBuilder(
                animation: _bg,
                child: content,
                builder: (context, child) => ColoredBox(
                  color: Color.lerp(
                    c.canvas,
                    AppFixedColors.momentBg,
                    _bg.value.clamp(0.0, 1.0),
                  )!,
                  child: child,
                ),
              )
            : ColoredBox(color: c.canvas, child: content),
      ),
    );
  }

  // ───────────── oybirliği (DecisionA) ─────────────

  Widget _unanimous(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = context.text;
    const ink = AppFixedColors.momentInk;

    return _Scroller(
      safeTop: true,
      builder: (context) => Column(
        children: [
          const SizedBox(height: AppSpacing.xxxl),
          _momentAvatars(context),
          const SizedBox(height: AppSpacing.xxl),
          FadeTransition(
            opacity: _arcFade,
            child: AgreementArc(
              loveCount: widget.loveCount,
              okCount: widget.okCount,
              total: widget.total,
              size: AgreementArcSize.large,
              onMoment: true,
              reveal: _arcReveal,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          _rise(
            _title,
            _titleRise,
            Semantics(
              header: true,
              child: ClampedTextScale.display(
                child: Text(
                  l10n.decisionUnanimous,
                  textAlign: TextAlign.center,
                  style: text.display.copyWith(color: ink),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          _rise(_card, _cardRise, _placeCard(context)),
          const Spacer(),
          const SizedBox(height: AppSpacing.xl),
          _actionsBlock(
            context,
            primary: AppButton.moment(
              label: l10n.decisionDirections,
              icon: AppIcons.map,
              onPressed: widget.onDirections,
            ),
            secondary: AppButton.momentGhost(
              label: l10n.decisionShare,
              icon: AppIcons.share,
              size: AppButtonSize.medium,
              fullWidth: true,
              onPressed: widget.onShare,
            ),
            tertiary: AppButton.momentText(
              label: AppLocalizations.of(context).commonClose,
              size: AppButtonSize.medium,
              fullWidth: true,
              onPressed: widget.onClose,
            ),
          ),
        ],
      ),
    );
  }

  /// Avatar kümesi: 56'lık, 3px `momentBg` halka; kenarlardan merkeze gelir. Temas anında
  /// halka dalgası yayılır.
  Widget _momentAvatars(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final people = widget.participants.take(DecisionMoment.maxAvatars).toList();
    final names = widget.participants.map((p) => p.name).join(', ');
    final width = MediaQuery.sizeOf(context).width;
    return Semantics(
      label: l10n.decisionParticipants(names),
      child: ExcludeSemantics(
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            _AvatarRow(
              people: people,
              progress: _reduce ? const AlwaysStoppedAnimation(1) : _avatars,
              ringColor: AppFixedColors.momentBg,
              ringWidth: _momentRing,
              fromEdge: width,
              reduce: _reduce,
            ),
            if (!_reduce)
              IgnorePointer(
                child: AnimatedBuilder(
                  animation: _wave,
                  builder: (context, _) {
                    final w = _wave.value.clamp(0.0, 1.0);
                    if (w <= 0 || w >= 1) return const SizedBox.shrink();
                    return Opacity(
                      opacity: 1 - w,
                      child: Transform.scale(
                        scale: 1 + _waveGrowth * w,
                        child: DecoratedBox(
                          decoration: AppRadius.circle(
                            side: const BorderSide(
                              color: AppFixedColors.momentInk,
                              width: _waveStroke,
                            ),
                          ),
                          child: const SizedBox.square(dimension: _waveBase),
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Mockup: avatarlar %25 üst üste (grup bileşeninin %30'undan biraz seyrek).
  static const double _momentOverlap = 0.25;
  static const double _momentRing = 3;
  static const double _waveBase = 62;
  static const double _waveStroke = 2;
  static const double _waveGrowth = 3;

  /// `surface` mekan kartı (E2): 56 thumbnail + `title` + `caption`.
  Widget _placeCard(BuildContext context) {
    final c = context.colors;
    final text = context.text;
    final meta = widget.meta.plain(context, includeRating: false);
    return Semantics(
      container: true,
      label: [
        widget.placeName,
        widget.meta.spoken(context),
      ].where((s) => s.isNotEmpty).join(', '),
      child: ExcludeSemantics(
        child: DecoratedBox(
          decoration: AppRadius.decoration(
            radius: AppRadius.lg,
            color: c.surface,
            elevation: context.elevation.e2,
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: Row(
              children: [
                resultThumb(widget.photo),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.placeName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: text.title,
                      ),
                      if (meta.isNotEmpty)
                        Text(
                          meta,
                          style: text.caption.tabular.copyWith(
                            color: c.textSecondary,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ───────────── çoğunluk (DecisionB) ─────────────

  Widget _majority(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = context.colors;
    final text = context.text;
    final meta = widget.meta.plain(context, includeRating: false);
    final safeTop = MediaQuery.paddingOf(context).top;
    final people = widget.participants;
    final names = people.map((p) => p.name).join(', ');

    return _Scroller(
      safeTop: false,
      builder: (context) => Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              AspectRatio(
                aspectRatio: _photoAspect,
                child: SizedBox.expand(child: widget.photo),
              ),
              Positioned(
                left: AppSpacing.sm,
                top: safeTop + AppSpacing.xs,
                child: AppIconButton.media(
                  icon: AppIcons.close,
                  semanticLabel: l10n.commonClose,
                  onPressed: widget.onClose,
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                // Avatarın merkezi fotoğrafın alt kenarında: halka da dışarıda kalır.
                bottom: -(_avatarOverhang + _majorityRing),
                child: Center(
                  child: Semantics(
                    label: l10n.decisionParticipants(names),
                    child: ExcludeSemantics(
                      child: AppAvatarGroup(
                        people: people,
                        size: AppAvatarSize.lg,
                        maxVisible: DecisionMoment.maxAvatars,
                        ringColor: c.canvas,
                        ringWidth: _majorityRing,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: _avatarOverhang + AppSpacing.xl),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenPadding,
            ),
            child: Column(
              children: [
                _rise(
                  _title,
                  _titleRise,
                  Semantics(
                    header: true,
                    child: ClampedTextScale.display(
                      child: Text(
                        l10n.decisionMajority,
                        textAlign: TextAlign.center,
                        style: text.display.copyWith(color: c.textPrimary),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                _rise(
                  _info,
                  _titleRise,
                  Semantics(
                    container: true,
                    label: [
                      widget.placeName,
                      widget.meta.spoken(context),
                    ].where((s) => s.isNotEmpty).join(', '),
                    child: ExcludeSemantics(
                      child: Column(
                        children: [
                          Text(
                            widget.placeName,
                            textAlign: TextAlign.center,
                            style: text.h3,
                          ),
                          if (meta.isNotEmpty)
                            Text(
                              meta,
                              textAlign: TextAlign.center,
                              style: text.caption.tabular.copyWith(
                                color: c.textSecondary,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                _rise(
                  _tag,
                  _titleRise,
                  _VoteTag(
                    label: l10n.decisionVotes(widget.votes, widget.totalVotes),
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          const SizedBox(height: AppSpacing.xl),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenPadding,
            ),
            child: _actionsBlock(
              context,
              primary: AppButton.primary(
                label: l10n.decisionDirections,
                icon: AppIcons.map,
                onPressed: widget.onDirections,
              ),
              secondary: AppButton.secondary(
                label: l10n.decisionShare,
                icon: AppIcons.share,
                size: AppButtonSize.medium,
                fullWidth: true,
                onPressed: widget.onShare,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Fotoğraf oranı (mockup: 390 × 400).
  static const double _photoAspect = 390 / 400;
  static const double _avatarOverhang = 28;
  static const double _majorityRing = 4;

  // ───────────── ortak ─────────────

  /// Belirme: opaklık + yukarı kayma ([rise] pt). Reduce Motion'da yalnızca opaklık.
  Widget _rise(Animation<double> a, double rise, Widget child) {
    return AnimatedBuilder(
      animation: a,
      child: child,
      builder: (context, c) {
        final v = a.value;
        return Opacity(
          opacity: v.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, _reduce ? 0 : rise * (1 - v)),
            child: c,
          ),
        );
      },
    );
  }

  /// Eylemler: kart ile birlikte belirir; koreografi bitene kadar dokunulmaz.
  Widget _actionsBlock(
    BuildContext context, {
    required Widget primary,
    required Widget secondary,
    Widget? tertiary,
  }) {
    return AnimatedBuilder(
      animation: _c,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          primary,
          const SizedBox(height: AppSpacing.xs),
          secondary,
          if (tertiary != null) ...[
            const SizedBox(height: AppSpacing.xs),
            tertiary,
          ],
        ],
      ),
      builder: (context, child) => IgnorePointer(
        ignoring: !_c.isCompleted,
        child: Opacity(opacity: _actions.value.clamp(0.0, 1.0), child: child),
      ),
    );
  }
}

/// Dikeyde ekranı dolduran, içerik büyüyünce kayan düzen (alttaki eylemler `Spacer` ile
/// aşağı itilir).
class _Scroller extends StatelessWidget {
  const _Scroller({required this.builder, required this.safeTop});

  final WidgetBuilder builder;
  final bool safeTop;

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.paddingOf(context);
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: IntrinsicHeight(
            child: Padding(
              padding: EdgeInsets.only(
                top: safeTop ? padding.top : 0,
                bottom: padding.bottom + AppSpacing.xs,
                left: safeTop ? AppSpacing.screenPadding : 0,
                right: safeTop ? AppSpacing.screenPadding : 0,
              ),
              child: builder(context),
            ),
          ),
        ),
      ),
    );
  }
}

/// Üst üste binen avatarlar; her biri kenardan merkeze gelir ([progress] 0 → 1, spring'de 1'i
/// aşabilir).
class _AvatarRow extends StatelessWidget {
  const _AvatarRow({
    required this.people,
    required this.progress,
    required this.ringColor,
    required this.ringWidth,
    required this.fromEdge,
    required this.reduce,
  });

  final List<AppAvatarPerson> people;
  final Animation<double> progress;
  final Color ringColor;
  final double ringWidth;
  final double fromEdge;
  final bool reduce;

  @override
  Widget build(BuildContext context) {
    final avatar = AppAvatarSize.lg.dimension;
    final outer = avatar + 2 * ringWidth;
    final step = outer * (1 - _DecisionMomentState._momentOverlap);
    final width = outer + (people.length - 1) * step;
    return SizedBox(
      width: width,
      height: outer,
      child: AnimatedBuilder(
        animation: progress,
        builder: (context, _) {
          final t = progress.value;
          return Stack(
            clipBehavior: Clip.none,
            children: [
              for (var i = 0; i < people.length; i++)
                Positioned(
                  left: i * step,
                  child: Opacity(
                    opacity: reduce ? t.clamp(0.0, 1.0) : 1,
                    child: Transform.translate(
                      offset: Offset(
                        reduce
                            ? 0
                            : (i < people.length / 2 ? -1 : 1) *
                                  fromEdge *
                                  (1 - t),
                        0,
                      ),
                      child: DecoratedBox(
                        decoration: AppRadius.circle(color: ringColor),
                        child: Padding(
                          padding: EdgeInsets.all(ringWidth),
                          child: AppAvatar(
                            userId: people[i].userId,
                            name: people[i].name,
                            image: people[i].image,
                            size: AppAvatarSize.lg,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

/// "3/4 oyla seçildi" etiketi: `brandSoft` zemin, `onBrandSoft` yazı, ✓ ikonu.
class _VoteTag extends StatelessWidget {
  const _VoteTag({required this.label});

  final String label;

  static const double _minHeight = 28;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: _minHeight),
      child: DecoratedBox(
        decoration: AppRadius.decoration(
          radius: AppRadius.pill,
          color: c.brandSoft,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(AppIcons.check, size: AppIconSize.s14, color: c.onBrandSoft),
              const SizedBox(width: AppSpacing.xxs + 2),
              Flexible(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: context.text.caption.tabular.copyWith(
                    color: c.onBrandSoft,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
