import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

import '../../foundations/app_icons.dart';
import '../../foundations/app_pressable.dart';
import '../../foundations/context_extensions.dart';
import '../../tokens/app_fixed_colors.dart';
import '../../tokens/app_motion.dart';
import '../../tokens/app_radius.dart';
import '../../tokens/app_spacing.dart';

/// Toast türü. **Warning yok** (DESIGN_SYSTEM.md §10): uyarılar toast'la verilmez.
enum AppToastKind {
  /// Nötr bilgi.
  neutral,

  /// Başarı ✓.
  success,

  /// Hata ⚠ (geçici hatalar için; ekran seviyesi hatalar nötr kalır).
  error,
}

/// Gösterilen toast'ı kapatmak için tutamaç (örn. "Geri al" akışında).
class AppToastHandle {
  AppToastHandle._(this._dismiss);

  final VoidCallback _dismiss;

  /// Toast'ı çıkış animasyonuyla kapatır; zaten kapandıysa bir şey yapmaz.
  void dismiss() => _dismiss();
}

/// Toast (DESIGN_SYSTEM.md §10 "Toast").
///
/// Ekranın **üstünde**, safe area + 8. Pill, `inverseSurface` + `inverseText`, E2, min 44,
/// yatay 16; solda 20'lik ikon, metin `bodySmall` en fazla 2 satır, isteğe bağlı eylem
/// (`inverseAction`). Süre 3 sn, eylemli 5 sn, VoiceOver açıkken eylemli 10 sn. Yukarı
/// kaydırarak kapanır. **Aynı anda tek toast**: yenisi eskisinin yerini alır.
abstract final class AppToast {
  static _ToastEntry? _current;

  static const Duration _plain = Duration(seconds: 3);
  static const Duration _withAction = Duration(seconds: 5);
  static const Duration _withActionAccessible = Duration(seconds: 10);

  /// Şu an bir toast görünüyor mu.
  static bool get isShowing => _current != null;

  static AppToastHandle show(
    BuildContext context, {
    required String message,
    AppToastKind kind = AppToastKind.neutral,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    assert(
      (actionLabel == null) == (onAction == null),
      'actionLabel ve onAction birlikte verilmeli.',
    );
    // Eski toast animasyonsuz kalkar; yenisi hemen gelir.
    _current?.removeNow();

    final overlay = Overlay.of(context, rootOverlay: true);
    final accessible = MediaQuery.accessibleNavigationOf(context);
    final duration = actionLabel == null
        ? _plain
        : (accessible ? _withActionAccessible : _withAction);

    final entry = _ToastEntry();
    entry.overlayEntry = OverlayEntry(
      builder: (context) => _ToastView(
        entry: entry,
        message: message,
        kind: kind,
        actionLabel: actionLabel,
        onAction: onAction,
        duration: duration,
      ),
    );
    _current = entry;
    overlay.insert(entry.overlayEntry);
    return AppToastHandle._(entry.requestDismiss);
  }
}

/// Ekranda olan tek toast'ın durumu.
class _ToastEntry {
  late OverlayEntry overlayEntry;
  VoidCallback? _animateOut;
  bool _removed = false;

  void requestDismiss() {
    if (_removed) return;
    if (_animateOut != null) {
      _animateOut!();
    } else {
      removeNow();
    }
  }

  void removeNow() {
    if (_removed) return;
    _removed = true;
    overlayEntry.remove();
    overlayEntry.dispose();
    if (AppToast._current == this) AppToast._current = null;
  }
}

class _ToastView extends StatefulWidget {
  const _ToastView({
    required this.entry,
    required this.message,
    required this.kind,
    required this.duration,
    this.actionLabel,
    this.onAction,
  });

  final _ToastEntry entry;
  final String message;
  final AppToastKind kind;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Duration duration;

  @override
  State<_ToastView> createState() => _ToastViewState();
}

class _ToastViewState extends State<_ToastView>
    with SingleTickerProviderStateMixin {
  static const double _enterOffset = AppSpacing.md;
  static const double _swipeDismissDistance = 24;
  static const double _swipeDismissVelocity = 300;

  // 0 = gizli, 1 = tam görünür; giriş spring ile taşabilir.
  late final AnimationController _visible = AnimationController.unbounded(
    vsync: this,
  );
  Timer? _timer;
  double _drag = 0;
  bool _leaving = false;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    widget.entry._animateOut = _leave;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    final motion = context.motion;
    if (motion.reduceMotion) {
      _visible.value = 1;
    } else {
      _visible.animateWith(SpringSimulation(motion.springStandard, 0, 1, 0));
    }
    _timer = Timer(widget.duration, _leave);
  }

  @override
  void dispose() {
    _timer?.cancel();
    widget.entry._animateOut = null;
    _visible.dispose();
    super.dispose();
  }

  Future<void> _leave() async {
    if (_leaving) return;
    _leaving = true;
    _timer?.cancel();
    final motion = context.motion;
    final duration = motion.exitOf(motion.standard);
    if (duration == Duration.zero || !mounted) {
      widget.entry.removeNow();
      return;
    }
    await _visible.animateTo(0, duration: duration, curve: AppMotion.exit);
    widget.entry.removeNow();
  }

  void _onDragUpdate(DragUpdateDetails d) {
    // Yalnızca yukarı: aşağı çekilmez.
    setState(
      () => _drag = (_drag + d.delta.dy).clamp(double.negativeInfinity, 0),
    );
  }

  void _onDragEnd(DragEndDetails d) {
    if (_drag <= -_swipeDismissDistance ||
        d.velocity.pixelsPerSecond.dy <= -_swipeDismissVelocity) {
      _leave();
    } else {
      setState(() => _drag = 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = context.text;
    final (IconData icon, Color iconColor) = switch (widget.kind) {
      AppToastKind.neutral => (AppIcons.info, AppFixedColors.inverseText),
      AppToastKind.success => (AppIcons.check, AppFixedColors.inverseSuccess),
      AppToastKind.error => (AppIcons.warning, AppFixedColors.inverseError),
    };

    final pill = DecoratedBox(
      decoration: AppRadius.decoration(
        radius: AppRadius.pill,
        color: AppFixedColors.inverseSurface,
        elevation: context.elevation.e2,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: AppSpacing.touchTarget),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: AppIconSize.s20, color: iconColor),
              const SizedBox(width: AppSpacing.xs),
              Flexible(
                child: Text(
                  widget.message,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: text.bodySmall.copyWith(
                    color: AppFixedColors.inverseText,
                  ),
                ),
              ),
              if (widget.actionLabel != null) ...[
                const SizedBox(width: AppSpacing.md),
                AppPressable(
                  onPressed: () {
                    widget.onAction!();
                    _leave();
                  },
                  semanticLabel: widget.actionLabel!,
                  scaleOnPress: false,
                  builder: (context, pressed) => ConstrainedBox(
                    constraints: const BoxConstraints(
                      minHeight: AppSpacing.touchTarget,
                    ),
                    child: Center(
                      widthFactor: 1,
                      child: AnimatedOpacity(
                        duration: context.motion.fast,
                        opacity: pressed ? 0.5 : 1,
                        child: Text(
                          widget.actionLabel!,
                          style: text.label.copyWith(
                            color: AppFixedColors.inverseAction,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );

    // Overlay'de Material atası yok: onsuz metinler Flutter'ın uyarı stiliyle (sarı altı çizgi)
    // çizilir. Saydam Material yalnızca varsayılan metin stilini sağlar.
    return Positioned(
      top: MediaQuery.paddingOf(context).top + AppSpacing.xs,
      left: AppSpacing.screenPadding,
      right: AppSpacing.screenPadding,
      child: Material(
        type: MaterialType.transparency,
        child: Center(
          child: AnimatedBuilder(
            animation: _visible,
            builder: (context, child) => Opacity(
              opacity: _visible.value.clamp(0.0, 1.0),
              child: Transform.translate(
                offset: Offset(0, (_visible.value - 1) * _enterOffset + _drag),
                child: child,
              ),
            ),
            child: Semantics(
              liveRegion: true,
              container: true,
              onDismiss: _leave,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onVerticalDragUpdate: _onDragUpdate,
                onVerticalDragEnd: _onDragEnd,
                child: pill,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
