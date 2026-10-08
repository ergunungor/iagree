import 'package:flutter/material.dart';

import '../../tokens/app_spacing.dart';
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
    return SafeArea(
      child: Column(
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
      ),
    );
  }
}
