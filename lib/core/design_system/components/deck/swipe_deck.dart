import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/semantics.dart';

import '../../../../l10n/app_localizations.dart';
import '../../foundations/app_haptics.dart';
import '../../foundations/app_icons.dart';
import '../../foundations/context_extensions.dart';
import '../../tokens/app_fixed_colors.dart';
import '../../tokens/app_motion.dart';
import '../../tokens/app_radius.dart';
import '../../tokens/app_spacing.dart';
import 'deck_card.dart';
import 'deck_decision_overlay.dart';
import 'swipe_deck_physics.dart';

/// Desteyi dışarıdan yöneten ve durumunu paylaşan denetleyici: butonlar, üst bar ve Geri al
/// bunun üzerinden deste ile konuşur. `ScrollController` gibi, bir `SwipeDeck`'e bağlanır.
class SwipeDeckController extends ChangeNotifier {
  final ValueNotifier<SwipeFrame> _frame = ValueNotifier(SwipeFrame.rest);
  _DeckHost? _host;

  int _index = 0;
  int _total = 0;
  bool _canUndo = false;
  bool _busy = false;

  /// Öndeki kartın sırası (0'dan).
  int get index => _index;

  /// Destedeki toplam kart.
  int get total => _total;

  /// Deste bitti mi.
  bool get isDone => _total > 0 && _index >= _total;

  /// Son kart geri alınabilir mi (tek seviye; uçuş sırasında kapalı).
  bool get canUndo => _canUndo;

  /// Kart uçuyor ya da geri geliyor.
  bool get busy => _busy;

  /// Öndeki kartın o anki sürükleme durumu (buton vurgusu için).
  ValueListenable<SwipeFrame> get frame => _frame;

  /// Kartı butonla ilgili yöne uçurur. Deste meşgulse ya da bitmişse yok sayılır.
  void swipe(DeckDecision decision) => _host?.swipeByButton(decision);

  /// Son kartı çıktığı yönden geri getirir.
  void undo() => _host?.undo();

  void _sync({
    required int index,
    required int total,
    required bool canUndo,
    required bool busy,
  }) {
    if (index == _index &&
        total == _total &&
        canUndo == _canUndo &&
        busy == _busy) {
      return;
    }
    _index = index;
    _total = total;
    _canUndo = canUndo;
    _busy = busy;
    notifyListeners();
  }

  @override
  void dispose() {
    _frame.dispose();
    super.dispose();
  }
}

abstract interface class _DeckHost {
  void swipeByButton(DeckDecision decision);
  void undo();
}

/// Kart destesi: arkada tek kart, öndeki kart dört yöne sürüklenir (DESIGN_SYSTEM.md §10
/// "SwipeDeck"). → Olur, ← Pas, ↑ Çok isterim, ↓ Olmaz.
///
/// Sürükleme, butonla tetikleme ([SwipeDeckController.swipe]), Geri al
/// ([SwipeDeckController.undo]), VoiceOver özel eylemleri, Reduce Motion'da solma ve ilk
/// kullanımdaki öğretici kıpırdama ([showHint]) burada. Fizik değerleri [SwipePhysics]'te;
/// üst bar ve butonlar [DeckTopBar] / [DeckActionBar], hepsini dizen yerleşim
/// `SwipeDeckScaffold`.
///
/// Genişliği ebeveyninden alır (ekran − 40); yükseklik sınırlıysa kart sığacak şekilde
/// küçülür (3:4 korunur). Deste tam ekran sayfada (push) yaşar; kaydırılan bir listenin
/// içinde dikey sürükleme kaydırmayla çakışır.
class SwipeDeck<T> extends StatefulWidget {
  const SwipeDeck({
    super.key,
    required this.items,
    required this.itemBuilder,
    this.controller,
    this.onSwiped,
    this.onUndo,
    this.onCompleted,
    this.showHint = false,
    this.onHintShown,
  });

  final List<T> items;

  /// Bir öğenin kartı; genelde bir [DeckCard]. Etiket/ton overlay'i `DeckCard` içinde otomatik.
  final Widget Function(BuildContext context, T item) itemBuilder;

  final SwipeDeckController? controller;

  /// Karar verildiği anda (uçuş başlarken).
  final void Function(T item, DeckDecision decision)? onSwiped;

  /// Geri al ile bir karar geri alındığında; uygulama oyu geri çeker.
  final void Function(T item, DeckDecision decision)? onUndo;

  /// Son kartın uçuşu bittiğinde.
  final VoidCallback? onCompleted;

  /// İlk kartta tek seferlik öğretici kıpırdama ve dört yön ipucu. "Bir kere" bilgisini
  /// çağıran tutar: gösterildikten ya da kullanıcı dokununca [onHintShown] çağrılır.
  final bool showHint;
  final VoidCallback? onHintShown;

  @override
  State<SwipeDeck<T>> createState() => _SwipeDeckState<T>();
}

class _SwipeDeckState<T> extends State<SwipeDeck<T>>
    with TickerProviderStateMixin
    implements _DeckHost {
  /// Arka kartın ölçeği ve aşağı kayması (öne gelince 1 ve 0).
  static const double _backScale = 0.95;
  static const double _backOffset = 8;

  /// Spring dönüşünde parmak hızından türetilen başlangıç hızının sınırı.
  static const double _maxSpringVelocity = 30;

  /// Öğretici kıpırdama: 24pt, 2 döngü, toplam 1,2 sn.
  static const double _hintAmplitude = 24;
  static const int _hintCycles = 2;
  static const Duration _hintDuration = Duration(milliseconds: 1200);

  late final SwipeDeckController _ctl;
  SwipeDeckController? _owned;

  int _index = 0;

  /// Uçmakta olan kartın öğe indeksi.
  int? _leavingIndex;
  bool _undoing = false;

  /// Geri alınabilecek son karar (tek seviye).
  ({int index, DeckDecision decision})? _last;

  final ValueNotifier<SwipeFrame> _restFrame = ValueNotifier(SwipeFrame.rest);

  /// Uçuş ve geri dönüş: 0 → 1 arası ilerleme (spring'de 1'i aşabilir).
  late final AnimationController _flight = AnimationController.unbounded(
    vsync: this,
  )..addListener(_onFlightTick);

  /// Öne gelen kartın 0,95 → 1 geçişi.
  late final AnimationController _promote = AnimationController.unbounded(
    vsync: this,
    value: 1,
  );

  /// Geri alınca öndeki kartın arka kata inişi (1 → 0). Dinlenmede 0.
  late final AnimationController _backPromote = AnimationController.unbounded(
    vsync: this,
  );

  /// Reduce Motion: uçan kartın solması (1 → 0).
  late final AnimationController _leavingOpacity = AnimationController(
    vsync: this,
    value: 1,
  );

  /// Reduce Motion: geri gelen kartın belirmesi (0 → 1).
  late final AnimationController _frontOpacity = AnimationController(
    vsync: this,
    value: 1,
  );

  late final AnimationController _hint = AnimationController(
    vsync: this,
    duration: _hintDuration,
  )..addListener(_onHintTick);

  ValueNotifier<SwipeFrame> get _frame => _ctl._frame;

  Size _card = Size.zero;
  Offset _finger = Offset.zero;
  Offset _origin = Offset.zero;
  bool _tracking = false;
  bool _armed = false;

  Offset _flightFrom = Offset.zero;
  Offset _flightTo = Offset.zero;

  bool get _busy => _leavingIndex != null || _undoing;

  @override
  void initState() {
    super.initState();
    _ctl = widget.controller ?? (_owned = SwipeDeckController());
    _ctl._host = this;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _publish();
      _maybeStartHint();
    });
  }

  @override
  void didUpdateWidget(SwipeDeck<T> old) {
    super.didUpdateWidget(old);
    assert(
      old.controller == widget.controller,
      'SwipeDeck.controller sonradan değiştirilemez.',
    );
    if (_index > widget.items.length) _index = widget.items.length;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _publish();
    });
  }

  @override
  void dispose() {
    if (_ctl._host == this) _ctl._host = null;
    _flight.dispose();
    _promote.dispose();
    _backPromote.dispose();
    _leavingOpacity.dispose();
    _frontOpacity.dispose();
    _hint.dispose();
    _restFrame.dispose();
    _owned?.dispose();
    super.dispose();
  }

  void _publish() => _ctl._sync(
    index: _index,
    total: widget.items.length,
    canUndo: _last != null && !_busy,
    busy: _busy,
  );

  // ───────────── öğretici kıpırdama ─────────────

  void _maybeStartHint() {
    if (!widget.showHint || _index != 0 || widget.items.isEmpty) return;
    // Reduce Motion'da hareket yok; ipucu gösterilmemiş sayılır.
    if (context.motion.reduceMotion) return;
    _hint.forward(from: 0).then((_) => _endHint());
  }

  void _endHint() {
    if (!mounted) return;
    _hint.value = 0;
    if (!_busy && !_tracking) _frame.value = SwipeFrame.rest;
    widget.onHintShown?.call();
  }

  void _cancelHint() {
    if (!_hint.isAnimating) return;
    _hint.stop();
    _endHint();
  }

  void _onHintTick() {
    if (_tracking || _busy) return;
    final x =
        _hintAmplitude * math.sin(2 * math.pi * _hintCycles * _hint.value);
    // Kıpırdama bir karar değildir: yalnızca konum ve dönme; etiket, ton ve buton vurgusu yok.
    final f = SwipePhysics.frame(Offset(x, 0), _card);
    _frame.value = SwipeFrame(offset: f.offset, rotation: f.rotation);
  }

  // ───────────── gesture ─────────────

  void _onPanStart(DragStartDetails d) {
    _tracking = false;
    if (_busy || _index >= widget.items.length) return;
    final screen = MediaQuery.sizeOf(context);
    // Ekranın alt kenarı sistem hareketlerine (ana ekran) ayrılmıştır.
    if (d.globalPosition.dy > screen.height - SwipePhysics.bottomGuard) return;

    _cancelHint();
    // Dönüş sırasında yakalanırsa kart olduğu yerden devam eder.
    _flight.stop();
    _origin = _frame.value.offset;
    _finger = Offset.zero;
    _tracking = true;
  }

  void _onPanUpdate(DragUpdateDetails d) {
    if (!_tracking) return;
    _finger += d.delta;
    // Eksen kilitli değil: baskın yön her harekette yeniden bulunur, bırakmadan değiştirilebilir.
    final offset = _origin + SwipePhysics.cardOffset(_finger);
    final frame = SwipePhysics.frame(offset, _card);
    // Eşiğe her girişte bir kez.
    if (frame.armed && !_armed) AppHaptics.selection();
    _armed = frame.armed;
    _frame.value = frame;
  }

  void _onPanEnd(DragEndDetails d) {
    if (!_tracking) return;
    _tracking = false;
    final velocity = d.velocity.pixelsPerSecond;
    final decision = SwipePhysics.decide(
      offset: _frame.value.offset,
      velocity: velocity,
      card: _card,
    );
    if (decision != null) {
      _commit(decision, velocity);
    } else {
      _springBack(velocity);
    }
  }

  void _onPanCancel() {
    if (!_tracking) return;
    _tracking = false;
    _springBack(Offset.zero);
  }

  // ───────────── dışarıdan tetikleme ─────────────

  @override
  void swipeByButton(DeckDecision decision) {
    if (_busy || _tracking || _index >= widget.items.length) return;
    _cancelHint();
    _flight.stop();
    _frame.value = SwipeFrame.rest;
    // Buton: `emphasis` süreli uçuş (spec).
    _commit(decision, Offset.zero, duration: context.motion.emphasis);
  }

  // ───────────── animasyon ─────────────

  /// Kararı uygular: kart uçar (Reduce Motion'da solar), arka kart öne gelir. Sürükleme ve
  /// butonlar aynı yoldan geçer.
  void _commit(DeckDecision decision, Offset velocity, {Duration? duration}) {
    final motion = context.motion;
    final screen = MediaQuery.sizeOf(context);
    final from = _frame.value.offset;
    final horizontal =
        decision == DeckDecision.ok || decision == DeckDecision.pass;

    _decisionHaptic(decision);
    final item = widget.items[_index];
    _last = (index: _index, decision: decision);
    _armed = false;
    setState(() {
      _leavingIndex = _index;
      _index++;
    });

    if (motion.reduceMotion) {
      _promote.value = 1;
    } else {
      _promote.value = 0;
      _promote.animateWith(SpringSimulation(motion.springStandard, 0, 1, 0));
    }

    widget.onSwiped?.call(item, decision);
    _announce(decision);
    _publish();

    if (motion.reduceMotion) {
      // Uçmak yerine yerinde solar (spec). Süreler 0 olduğundan solma süresi sabit.
      _leavingOpacity.value = 1;
      _leavingOpacity
          .animateTo(0, duration: AppMotion.regular.standard)
          .then((_) => _finishFlight());
      return;
    }

    final to = SwipePhysics.flyTarget(decision, from, screen);
    final distance = horizontal ? (to.dx - from.dx) : (to.dy - from.dy);
    final speed = horizontal ? velocity.dx : velocity.dy;
    final flyDuration =
        duration ??
        SwipePhysics.flyDuration(
          distance: distance,
          speed: speed,
          min: motion.fast,
          max: motion.exitOf(motion.emphasis),
        );
    _flightFrom = from;
    _flightTo = to;
    _flight.value = 0;
    _flight
        .animateTo(1, duration: flyDuration, curve: AppMotion.exit)
        .then((_) => _finishFlight());
  }

  void _finishFlight() {
    if (!mounted) return;
    _frame.value = SwipeFrame.rest;
    _leavingOpacity.value = 1;
    setState(() => _leavingIndex = null);
    _publish();
    if (_index >= widget.items.length) widget.onCompleted?.call();
  }

  /// Eşik geçilmediyse `springStandard` ile merkeze döner; bırakma hızı yaya aktarılır.
  void _springBack(Offset velocity) {
    final motion = context.motion;
    final from = _frame.value.offset;
    _armed = false;
    if (from == Offset.zero || motion.reduceMotion) {
      _frame.value = SwipeFrame.rest;
      return;
    }
    _flightFrom = from;
    _flightTo = Offset.zero;
    final toward = _flightTo - from;
    final v =
        ((velocity.dx * toward.dx + velocity.dy * toward.dy) /
                toward.distanceSquared)
            .clamp(-_maxSpringVelocity, _maxSpringVelocity);
    _flight.value = 0;
    _flight.animateWith(SpringSimulation(motion.springStandard, 0, 1, v)).then((
      _,
    ) {
      if (mounted) _frame.value = SwipeFrame.rest;
    });
  }

  /// Son kartı çıktığı yönden geri getirir; şimdiki ön kart arka kata iner.
  @override
  void undo() {
    final last = _last;
    if (last == null || _busy || _tracking) return;
    _cancelHint();
    final motion = context.motion;
    final screen = MediaQuery.sizeOf(context);

    AppHaptics.light();
    _last = null;
    _undoing = true;
    _flight.stop();
    widget.onUndo?.call(widget.items[last.index], last.decision);
    setState(() => _index = last.index);
    _promote.value = 1;

    if (motion.reduceMotion) {
      _backPromote.value = 0;
      _frame.value = SwipeFrame.rest;
      _frontOpacity.value = 0;
      _frontOpacity
          .animateTo(1, duration: AppMotion.regular.standard)
          .then((_) => _finishUndo());
    } else {
      _backPromote.value = 1;
      _backPromote.animateWith(
        SpringSimulation(motion.springStandard, 1, 0, 0),
      );
      _flightFrom = SwipePhysics.flyTarget(last.decision, Offset.zero, screen);
      _flightTo = Offset.zero;
      _frame.value = SwipePhysics.frame(_flightFrom, _card);
      _flight.value = 0;
      _flight
          .animateWith(SpringSimulation(motion.springStandard, 0, 1, 0))
          .then((_) => _finishUndo());
    }
    _announceProgress();
    _publish();
  }

  void _finishUndo() {
    if (!mounted) return;
    _frame.value = SwipeFrame.rest;
    _frontOpacity.value = 1;
    setState(() => _undoing = false);
    _publish();
  }

  void _onFlightTick() {
    final offset = Offset.lerp(_flightFrom, _flightTo, _flight.value)!;
    _frame.value = SwipePhysics.frame(offset, _card);
  }

  void _decisionHaptic(DeckDecision decision) {
    switch (decision) {
      case DeckDecision.ok:
      case DeckDecision.pass:
        AppHaptics.light();
      case DeckDecision.love:
        AppHaptics.medium();
      case DeckDecision.veto:
        AppHaptics.rigid();
    }
  }

  // ───────────── erişilebilirlik ─────────────

  String _decisionName(AppLocalizations l10n, DeckDecision d) => switch (d) {
    DeckDecision.ok => l10n.deckDecisionOk,
    DeckDecision.pass => l10n.deckDecisionPass,
    DeckDecision.love => l10n.deckDecisionLove,
    DeckDecision.veto => l10n.deckDecisionVeto,
  };

  void _announce(DeckDecision decision) {
    if (!MediaQuery.accessibleNavigationOf(context)) return;
    final l10n = AppLocalizations.of(context);
    final next = _index < widget.items.length
        ? '. ${l10n.deckProgressSemantics(_index + 1, widget.items.length)}'
        : '';
    SemanticsService.sendAnnouncement(
      View.of(context),
      '${_decisionName(l10n, decision)}$next',
      Directionality.of(context),
    );
  }

  void _announceProgress() {
    if (!MediaQuery.accessibleNavigationOf(context)) return;
    final l10n = AppLocalizations.of(context);
    SemanticsService.sendAnnouncement(
      View.of(context),
      l10n.deckProgressSemantics(_index + 1, widget.items.length),
      Directionality.of(context),
    );
  }

  Map<CustomSemanticsAction, VoidCallback> _actions(AppLocalizations l10n) => {
    for (final d in DeckDecision.values)
      CustomSemanticsAction(label: _decisionName(l10n, d)): () =>
          swipeByButton(d),
  };

  // ───────────── görünüm ─────────────

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        // Yükseklik sınırlıysa kart sığacak şekilde küçülür (3:4 korunur).
        final width = constraints.hasBoundedHeight
            ? math.min(
                constraints.maxWidth,
                constraints.maxHeight * DeckCard.aspectRatio,
              )
            : constraints.maxWidth;
        _card = Size(width, width / DeckCard.aspectRatio);

        final items = widget.items;
        final none = const AlwaysStoppedAnimation<double>(1);
        final children = <Widget>[
          if (_index + 1 < items.length)
            _CardSlot(
              key: ValueKey(_index + 1),
              promote: _backPromote,
              opacity: none,
              frame: _restFrame,
              interactive: false,
              child: widget.itemBuilder(context, items[_index + 1]),
            ),
          if (_index < items.length)
            _CardSlot(
              key: ValueKey(_index),
              promote: _promote,
              opacity: _frontOpacity,
              frame: _leavingIndex == null ? _frame : _restFrame,
              interactive: !_busy,
              actions: _actions(l10n),
              child: widget.itemBuilder(context, items[_index]),
            ),
          if (_leavingIndex case final leaving?)
            _CardSlot(
              key: ValueKey(leaving),
              promote: none,
              opacity: _leavingOpacity,
              frame: _frame,
              interactive: false,
              child: widget.itemBuilder(context, items[leaving]),
            ),
          if (widget.showHint)
            Positioned.fill(
              child: _HintLegend(animation: _hint, cardHeight: _card.height),
            ),
        ];

        if (_index >= items.length && _leavingIndex == null) {
          return SizedBox(width: width, height: _card.height);
        }
        return SizedBox(
          width: width,
          child: GestureDetector(
            dragStartBehavior: DragStartBehavior.down,
            onPanStart: _onPanStart,
            onPanUpdate: _onPanUpdate,
            onPanEnd: _onPanEnd,
            onPanCancel: _onPanCancel,
            child: Stack(clipBehavior: Clip.none, children: children),
          ),
        );
      },
    );
  }
}

/// Destedeki tek kart. Üç rolde (arka, ön, uçan) ağaç şekli aynıdır; böylece kart rol
/// değiştirince (arka → ön → uçan) durumu (fotoğraf indeksi vb.) korunur.
class _CardSlot extends StatelessWidget {
  const _CardSlot({
    super.key,
    required this.promote,
    required this.opacity,
    required this.frame,
    required this.interactive,
    required this.child,
    this.actions = const {},
  });

  final Animation<double> promote;
  final Animation<double> opacity;
  final ValueListenable<SwipeFrame> frame;
  final bool interactive;
  final Map<CustomSemanticsAction, VoidCallback> actions;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final card = FadeTransition(
      opacity: opacity,
      child: IgnorePointer(
        ignoring: !interactive,
        child: RepaintBoundary(
          child: DeckCardScope(frame: frame, actions: actions, child: child),
        ),
      ),
    );

    // İçteki geçiş: arka kartın 0,95 ölçek ve 8pt aşağıdan öne gelmesi.
    final promoted = AnimatedBuilder(
      animation: promote,
      child: card,
      builder: (context, c) {
        final t = promote.value;
        return Transform.translate(
          offset: Offset(0, _SwipeDeckState._backOffset * (1 - t)),
          child: Transform.scale(
            scale:
                _SwipeDeckState._backScale +
                (1 - _SwipeDeckState._backScale) * t,
            child: c,
          ),
        );
      },
    );

    // Dıştaki sürükleme: kayma + alt ortadan dönme. Kart içeriği her karede yeniden kurulmaz.
    return ValueListenableBuilder<SwipeFrame>(
      valueListenable: frame,
      child: promoted,
      builder: (context, f, c) => Transform.translate(
        offset: f.offset,
        child: Transform.rotate(
          angle: f.rotation,
          alignment: Alignment.bottomCenter,
          child: c,
        ),
      ),
    );
  }
}

/// İlk kartta kıpırdama sürerken kartın dört kenarında beliren yön ipucu. Kıpırdamanın başında
/// belirir, sonunda solar.
class _HintLegend extends StatelessWidget {
  const _HintLegend({required this.animation, required this.cardHeight});

  final Animation<double> animation;
  final double cardHeight;

  /// Fotoğraf alanı kartın ~%78'i; ipuçları bunun içinde kalır.
  static const double _photoFraction = 0.78;
  static const double _fade = 0.15;
  static const double _edge = AppSpacing.sm;
  static const double _topExtra = AppSpacing.xl;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: ExcludeSemantics(
        child: AnimatedBuilder(
          animation: animation,
          builder: (context, _) {
            final t = animation.value;
            if (t <= 0 || t >= 1) return const SizedBox.shrink();
            final opacity = t < _fade
                ? t / _fade
                : (t > 1 - _fade ? (1 - t) / _fade : 1.0);
            final l10n = AppLocalizations.of(context);
            return Opacity(
              opacity: opacity,
              child: Align(
                alignment: Alignment.topCenter,
                child: SizedBox(
                  height: cardHeight * _photoFraction,
                  child: Stack(
                    children: [
                      Align(
                        alignment: Alignment.topCenter,
                        child: Padding(
                          padding: const EdgeInsets.only(top: _topExtra),
                          child: _pill(
                            context,
                            AppIcons.heartFill,
                            l10n.deckDecisionLove,
                          ),
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: const EdgeInsets.only(left: _edge),
                          child: _pill(
                            context,
                            AppIcons.close,
                            l10n.deckDecisionPass,
                          ),
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Padding(
                          padding: const EdgeInsets.only(right: _edge),
                          child: _pill(
                            context,
                            AppIcons.check,
                            l10n.deckDecisionOk,
                          ),
                        ),
                      ),
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: _edge),
                          child: _pill(
                            context,
                            AppIcons.prohibit,
                            l10n.deckDecisionVeto,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _pill(BuildContext context, IconData icon, String label) {
    return DecoratedBox(
      decoration: AppRadius.decoration(
        radius: AppRadius.pill,
        color: AppFixedColors.mediaOverlay,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xxs,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: AppIconSize.s16, color: AppFixedColors.onMedia),
            const SizedBox(width: AppSpacing.xxs),
            Text(
              label,
              style: context.text.label.copyWith(color: AppFixedColors.onMedia),
            ),
          ],
        ),
      ),
    );
  }
}
