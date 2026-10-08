import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

import '../../foundations/app_haptics.dart';
import '../../foundations/context_extensions.dart';
import '../../tokens/app_motion.dart';
import 'deck_card.dart';
import 'deck_decision_overlay.dart';
import 'swipe_deck_physics.dart';

/// Kart destesi: arkada tek kart, öndeki kart dört yöne sürüklenir (DESIGN_SYSTEM.md §10
/// "SwipeDeck"). → Olur, ← Pas, ↑ Çok isterim, ↓ Olmaz.
///
/// Bu sürüm yalnızca kart yığını ve gesture fiziğidir; üst bar, alt butonlar, Geri al ve
/// erişilebilirlik eylemleri sonraki adımda eklenir. Fizik değerleri [SwipePhysics]'te.
///
/// Genişliği ebeveyninden alır (ekran − 40), yüksekliği kartın 3:4 oranıdır. Deste tam ekran
/// sayfada (push) yaşar; kaydırılan bir listenin içinde dikey sürükleme kaydırmayla çakışır.
class SwipeDeck<T> extends StatefulWidget {
  const SwipeDeck({
    super.key,
    required this.items,
    required this.itemBuilder,
    this.onSwiped,
    this.onCompleted,
  });

  final List<T> items;

  /// Bir öğenin kartı; genelde bir [DeckCard]. Etiket/ton overlay'i `DeckCard` içinde otomatik.
  final Widget Function(BuildContext context, T item) itemBuilder;

  /// Karar verildiği anda (uçuş başlarken).
  final void Function(T item, DeckDecision decision)? onSwiped;

  /// Son kartın uçuşu bittiğinde.
  final VoidCallback? onCompleted;

  @override
  State<SwipeDeck<T>> createState() => _SwipeDeckState<T>();
}

class _SwipeDeckState<T> extends State<SwipeDeck<T>>
    with TickerProviderStateMixin {
  /// Arka kartın ölçeği ve aşağı kayması (öne gelince 1 ve 0).
  static const double _backScale = 0.95;
  static const double _backOffset = 8;

  /// Spring dönüşünde parmak hızından türetilen başlangıç hızının sınırı.
  static const double _maxSpringVelocity = 30;

  int _index = 0;

  /// Uçmakta olan kartın öğe indeksi.
  int? _leavingIndex;

  final ValueNotifier<SwipeFrame> _frame = ValueNotifier(SwipeFrame.rest);
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

  Size _card = Size.zero;
  Offset _finger = Offset.zero;
  Offset _origin = Offset.zero;
  DeckAxis? _axis;
  bool _tracking = false;
  bool _armed = false;

  Offset _flightFrom = Offset.zero;
  Offset _flightTo = Offset.zero;
  DeckAxis? _flightAxis;

  @override
  void didUpdateWidget(SwipeDeck<T> old) {
    super.didUpdateWidget(old);
    if (_index > widget.items.length) _index = widget.items.length;
  }

  @override
  void dispose() {
    _flight.dispose();
    _promote.dispose();
    _frame.dispose();
    _restFrame.dispose();
    super.dispose();
  }

  // ───────────── gesture ─────────────

  void _onPanStart(DragStartDetails d) {
    _tracking = false;
    if (_leavingIndex != null || _index >= widget.items.length) return;
    final screen = MediaQuery.sizeOf(context);
    // Ekranın alt kenarı sistem hareketlerine (ana ekran) ayrılmıştır.
    if (d.globalPosition.dy > screen.height - SwipePhysics.bottomGuard) return;

    // Dönüş sırasında yakalanırsa kart olduğu yerden devam eder.
    _flight.stop();
    _origin = _frame.value.offset;
    if (_origin == Offset.zero) _axis = null;
    _finger = Offset.zero;
    _tracking = true;
  }

  void _onPanUpdate(DragUpdateDetails d) {
    if (!_tracking) return;
    _finger += d.delta;
    _axis ??= SwipePhysics.lockAxis(_finger);
    final axis = _axis;
    final offset = axis == null
        ? _origin + _finger
        : _origin + SwipePhysics.cardOffset(_finger, axis);
    final frame = SwipePhysics.frame(offset, axis, _card);
    // Eşiğe her girişte bir kez.
    if (frame.armed && !_armed) AppHaptics.selection();
    _armed = frame.armed;
    _frame.value = frame;
  }

  void _onPanEnd(DragEndDetails d) {
    if (!_tracking) return;
    _tracking = false;
    final axis = _axis;
    final velocity = d.velocity.pixelsPerSecond;
    if (axis != null) {
      final decision = SwipePhysics.decide(
        offset: _frame.value.offset,
        axis: axis,
        velocity: velocity,
        card: _card,
      );
      if (decision != null) {
        _commit(decision, velocity);
        return;
      }
    }
    _springBack(velocity);
  }

  void _onPanCancel() {
    if (!_tracking) return;
    _tracking = false;
    _springBack(Offset.zero);
  }

  // ───────────── animasyon ─────────────

  /// Kararı uygular: kart uçar, arka kart öne gelir. C4'te butonlar ve Geri al da buradan geçer.
  void _commit(DeckDecision decision, Offset velocity) {
    final motion = context.motion;
    final screen = MediaQuery.sizeOf(context);
    final from = _frame.value.offset;
    final axis = switch (decision) {
      DeckDecision.ok || DeckDecision.pass => DeckAxis.horizontal,
      DeckDecision.love || DeckDecision.veto => DeckAxis.vertical,
    };
    final to = SwipePhysics.flyTarget(decision, from, screen);
    final horizontal = axis == DeckAxis.horizontal;
    final distance = horizontal ? (to.dx - from.dx) : (to.dy - from.dy);
    final speed = horizontal ? velocity.dx : velocity.dy;
    final duration = SwipePhysics.flyDuration(
      distance: distance,
      speed: speed,
      min: motion.fast,
      max: motion.exitOf(motion.emphasis),
    );

    final item = widget.items[_index];
    _flightFrom = from;
    _flightTo = to;
    _flightAxis = axis;
    _axis = axis;
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
    _flight.value = 0;
    _flight
        .animateTo(1, duration: duration, curve: AppMotion.exit)
        .then((_) => _finishFlight());
  }

  void _finishFlight() {
    if (!mounted) return;
    _frame.value = SwipeFrame.rest;
    _axis = null;
    setState(() => _leavingIndex = null);
    if (_index >= widget.items.length) widget.onCompleted?.call();
  }

  /// Eşik geçilmediyse `springStandard` ile merkeze döner; bırakma hızı yaya aktarılır.
  void _springBack(Offset velocity) {
    final motion = context.motion;
    final from = _frame.value.offset;
    _armed = false;
    if (from == Offset.zero || motion.reduceMotion) {
      _settle();
      return;
    }
    _flightFrom = from;
    _flightTo = Offset.zero;
    _flightAxis = _axis;
    final toward = _flightTo - from;
    final v =
        ((velocity.dx * toward.dx + velocity.dy * toward.dy) /
                toward.distanceSquared)
            .clamp(-_maxSpringVelocity, _maxSpringVelocity);
    _flight.value = 0;
    _flight
        .animateWith(SpringSimulation(motion.springStandard, 0, 1, v))
        .then((_) => _settle());
  }

  void _settle() {
    if (!mounted) return;
    _frame.value = SwipeFrame.rest;
    _axis = null;
  }

  void _onFlightTick() {
    final offset = Offset.lerp(_flightFrom, _flightTo, _flight.value)!;
    _frame.value = SwipePhysics.frame(offset, _flightAxis, _card);
  }

  // ───────────── görünüm ─────────────

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        _card = Size(width, width / DeckCard.aspectRatio);

        final items = widget.items;
        final children = <Widget>[
          if (_index + 1 < items.length)
            _CardSlot(
              key: ValueKey(_index + 1),
              promote: const AlwaysStoppedAnimation<double>(0),
              frame: _restFrame,
              interactive: false,
              child: widget.itemBuilder(context, items[_index + 1]),
            ),
          if (_index < items.length)
            _CardSlot(
              key: ValueKey(_index),
              promote: _promote,
              frame: _leavingIndex == null ? _frame : _restFrame,
              interactive: _leavingIndex == null,
              child: widget.itemBuilder(context, items[_index]),
            ),
          if (_leavingIndex case final leaving?)
            _CardSlot(
              key: ValueKey(leaving),
              promote: const AlwaysStoppedAnimation<double>(1),
              frame: _frame,
              interactive: false,
              child: widget.itemBuilder(context, items[leaving]),
            ),
        ];

        if (children.isEmpty) {
          return SizedBox(width: width, height: _card.height);
        }
        return GestureDetector(
          dragStartBehavior: DragStartBehavior.down,
          onPanStart: _onPanStart,
          onPanUpdate: _onPanUpdate,
          onPanEnd: _onPanEnd,
          onPanCancel: _onPanCancel,
          child: Stack(clipBehavior: Clip.none, children: children),
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
    required this.frame,
    required this.interactive,
    required this.child,
  });

  final Animation<double> promote;
  final ValueListenable<SwipeFrame> frame;
  final bool interactive;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final card = IgnorePointer(
      ignoring: !interactive,
      child: RepaintBoundary(
        child: DeckPhotoOverlayScope(frame: frame, child: child),
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
