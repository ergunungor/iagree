import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../foundations/context_extensions.dart';
import '../../tokens/app_motion.dart';
import '../../tokens/app_spacing.dart';
import 'deck_decision_overlay.dart';
import 'deck_action_bar.dart';
import 'deck_top_bar.dart';
import 'swipe_deck.dart';
import 'swipe_deck_physics.dart';

/// Deste ekranının yerleşimi (DESIGN_SYSTEM.md §10 "SwipeDeck", SCREENS D4): üstte
/// [DeckTopBar], altta [DeckActionBar] (başparmak bölgesi), kart ikisinin arasındaki alanın
/// dikey ortasında. Safe area'yı kendisi yönetir; tam ekran sayfanın gövdesi olarak kullanılır.
class SwipeDeckScaffold<T> extends StatefulWidget {
  const SwipeDeckScaffold({
    super.key,
    required this.items,
    required this.itemBuilder,
    this.controller,
    this.onBack,
    this.onSwiped,
    this.onUndo,
    this.onCompleted,
    this.showHint = false,
    this.onHintShown,
  });

  final List<T> items;
  final Widget Function(BuildContext context, T item) itemBuilder;
  final SwipeDeckController? controller;
  final VoidCallback? onBack;
  final void Function(T item, DeckDecision decision)? onSwiped;
  final void Function(T item, DeckDecision decision)? onUndo;
  final VoidCallback? onCompleted;
  final bool showHint;
  final VoidCallback? onHintShown;

  @override
  State<SwipeDeckScaffold<T>> createState() => _SwipeDeckScaffoldState<T>();
}

class _SwipeDeckScaffoldState<T> extends State<SwipeDeckScaffold<T>> {
  SwipeDeckController? _owned;

  SwipeDeckController get _controller =>
      widget.controller ?? (_owned ??= SwipeDeckController());

  @override
  void dispose() {
    _owned?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    return Stack(
      fit: StackFit.expand,
      children: [
        // Sürüklerken ekran zemini kararın tonuna boyanır (alt butonlar sabit kalır).
        _ScreenTint(frame: controller.frame),
        SafeArea(child: _content(controller)),
      ],
    );
  }

  Widget _content(SwipeDeckController controller) {
    return Column(
      children: [
        DeckTopBar(controller: controller, onBack: widget.onBack),
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenPadding,
              ),
              child: SwipeDeck<T>(
                items: widget.items,
                itemBuilder: widget.itemBuilder,
                controller: controller,
                onSwiped: widget.onSwiped,
                onUndo: widget.onUndo,
                onCompleted: widget.onCompleted,
                showHint: widget.showHint,
                onHintShown: widget.onHintShown,
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(
            top: AppSpacing.xs,
            bottom: AppSpacing.xs,
          ),
          child: DeckActionBar(controller: controller),
        ),
      ],
    );
  }
}

/// Sürükleme sırasında ekran zeminini kararın tonuyla boyar. Parmakla birlikte gecikmesiz
/// izler; karar verilip kart uçunca ton bir anda kesilmez, `standard` sürede solar.
class _ScreenTint extends StatefulWidget {
  const _ScreenTint({required this.frame});

  final ValueListenable<SwipeFrame> frame;

  @override
  State<_ScreenTint> createState() => _ScreenTintState();
}

class _ScreenTintState extends State<_ScreenTint>
    with SingleTickerProviderStateMixin {
  /// Bu opaklığın altındaki ani kesilmeler fark edilmez; solma gerekmez.
  static const double _fadeThreshold = 0.02;

  late final AnimationController _fade = AnimationController(vsync: this);
  Color _tint = Colors.transparent;
  double _alpha = 0;
  double _fadeFrom = 0;

  @override
  void initState() {
    super.initState();
    widget.frame.addListener(_onFrame);
  }

  @override
  void didUpdateWidget(_ScreenTint old) {
    super.didUpdateWidget(old);
    if (old.frame != widget.frame) {
      old.frame.removeListener(_onFrame);
      widget.frame.addListener(_onFrame);
    }
  }

  @override
  void dispose() {
    widget.frame.removeListener(_onFrame);
    _fade.dispose();
    super.dispose();
  }

  void _onFrame() {
    final f = widget.frame.value;
    final d = f.direction;
    final target = d == null ? 0.0 : f.screenTintAlpha;
    if (d != null) _tint = deckDecisionTint(context.colors, d);

    if (target == 0 && _alpha > _fadeThreshold) {
      // Karar verildi ya da kart bırakıldı: ton solar.
      _fadeFrom = _alpha;
      _alpha = 0;
      _fade.duration = context.motion.standard;
      _fade.forward(from: 0);
      return;
    }
    if (target > 0 || _alpha > 0) {
      _fade.stop();
      setState(() => _alpha = target);
    }
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _fade,
        builder: (context, _) {
          final alpha = _fade.isAnimating
              ? _fadeFrom * (1 - AppMotion.exit.transform(_fade.value))
              : _alpha;
          if (alpha <= 0) return const SizedBox.expand();
          return ColoredBox(color: _tint.withValues(alpha: alpha));
        },
      ),
    );
  }
}
