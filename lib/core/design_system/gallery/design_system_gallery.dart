import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

import '../components/brand/app_logo.dart';
import '../components/buttons/app_button.dart';
import '../components/buttons/app_icon_button.dart';
import '../components/inputs/app_search_field.dart';
import '../components/inputs/app_text_field.dart';
import '../foundations/app_haptics.dart';
import '../foundations/app_icons.dart';
import '../foundations/app_theme.dart';
import '../foundations/clamped_text_scale.dart';
import '../foundations/context_extensions.dart';
import '../tokens/app_colors.dart';
import '../tokens/app_fixed_colors.dart';
import '../tokens/app_motion.dart';
import '../tokens/app_radius.dart';
import '../tokens/app_spacing.dart';
import '../tokens/app_typography.dart';

/// Yalnızca debug build'de açılan design system galerisi. Her yeni component buraya bir bölüm
/// olarak eklenir. Geliştirici aracı olduğu için metinler Türkçe sabit, l10n dışında.
class DesignSystemGallery extends StatefulWidget {
  const DesignSystemGallery({
    super.key,
    this.initialDark,
    this.initialTextScale = 1,
  });

  /// Boşsa sistem temasını izler.
  final bool? initialDark;
  final double initialTextScale;

  @override
  State<DesignSystemGallery> createState() => _DesignSystemGalleryState();
}

class _DesignSystemGalleryState extends State<DesignSystemGallery> {
  late bool? _dark = widget.initialDark;
  late double _textScale = widget.initialTextScale;

  @override
  Widget build(BuildContext context) {
    final dark =
        _dark ?? MediaQuery.platformBrightnessOf(context) == Brightness.dark;
    return Theme(
      data: dark ? AppTheme.dark : AppTheme.light,
      child: MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(_textScale)),
        child: Builder(
          builder: (context) => Scaffold(
            body: SafeArea(
              child: Column(
                children: [
                  _Controls(
                    dark: dark,
                    bigText: _textScale > 1,
                    onDark: (v) => setState(() => _dark = v),
                    onBigText: (v) => setState(() => _textScale = v ? 2 : 1),
                  ),
                  const Expanded(child: _Sections()),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Controls extends StatelessWidget {
  const _Controls({
    required this.dark,
    required this.bigText,
    required this.onDark,
    required this.onBigText,
  });

  final bool dark;
  final bool bigText;
  final ValueChanged<bool> onDark;
  final ValueChanged<bool> onBigText;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    Widget toggle(String label, bool value, ValueChanged<bool> onChanged) =>
        Expanded(
          child: Row(
            children: [
              CupertinoSwitch(
                value: value,
                onChanged: onChanged,
                activeTrackColor: c.brand,
                inactiveTrackColor: c.trackOff,
              ),
              const SizedBox(width: AppSpacing.xs),
              Flexible(child: Text(label, style: context.text.label)),
            ],
          ),
        );
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: c.border)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.screenPadding,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: [
            toggle('Koyu tema', dark, onDark),
            toggle('Yazı 2x', bigText, onBigText),
          ],
        ),
      ),
    );
  }
}

class _Sections extends StatelessWidget {
  const _Sections();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Section('Renk', _ColorSection()),
          _Section('Tipografi', _TypographySection()),
          _Section('Spacing', _SpacingSection()),
          _Section('Radius', _RadiusSection()),
          _Section('Elevation', _ElevationSection()),
          _Section('İkonlar', _IconSection()),
          _Section('Hareket', _MotionSection()),
          _Section('Logo', _LogoSection()),
          _Section('Buton', _ButtonSection()),
          _Section('İkon butonu', _IconButtonSection()),
          _Section('Metin alanı', _TextFieldSection()),
          _Section('Arama alanı', _SearchFieldSection()),
          _Section('Haptik', _HapticsSection()),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section(this.title, this.child);

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sectionGap),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: context.text.h2),
          const SizedBox(height: AppSpacing.sm),
          child,
        ],
      ),
    );
  }
}

class _Caption extends StatelessWidget {
  const _Caption(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: context.text.caption.tabular.copyWith(
      color: context.colors.textSecondary,
    ),
  );
}

// ---------------------------------------------------------------- Renk

class _ColorSection extends StatelessWidget {
  const _ColorSection();

  static String hex(Color color) {
    final v = color.toARGB32();
    final rgb = (v & 0xFFFFFF).toRadixString(16).padLeft(6, '0');
    final a = v >>> 24;
    return a == 0xFF ? '#$rgb' : '#$rgb${a.toRadixString(16).padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final groups = <String, Map<String, Color>>{
      'Yüzey': {
        'canvas': c.canvas,
        'surface': c.surface,
        'surfaceRaised': c.surfaceRaised,
        'surfaceMuted': c.surfaceMuted,
        'surfacePressed': c.surfacePressed,
        'surfaceInputFocus': c.surfaceInputFocus,
        'trackOff': c.trackOff,
      },
      'Metin': {
        'textPrimary': c.textPrimary,
        'textSecondary': c.textSecondary,
        'textTertiary': c.textTertiary,
        'textDisabled': c.textDisabled,
      },
      'Kenar': {'border': c.border, 'borderControl': c.borderControl},
      'Marka': {
        'brand': c.brand,
        'brandPressed': c.brandPressed,
        'onBrand': c.onBrand,
        'brandSoft': c.brandSoft,
        'onBrandSoft': c.onBrandSoft,
        'brandMuted': c.brandMuted,
        'focusRing': c.focusRing,
      },
      'Durum': {
        'success': c.success,
        'successSoft': c.successSoft,
        'warning': c.warning,
        'warningSoft': c.warningSoft,
        'error': c.error,
        'errorSoft': c.errorSoft,
        'onError': c.onError,
      },
      'Katman': {'scrim': c.scrim},
      'Avatar': {
        'avatarSand': c.avatarSand,
        'avatarSage': c.avatarSage,
        'avatarMist': c.avatarMist,
        'avatarRose': c.avatarRose,
        'avatarLavender': c.avatarLavender,
      },
      'Sabit: karar anı': {
        'momentBg': AppFixedColors.momentBg,
        'momentInk': AppFixedColors.momentInk,
        'momentTrack': AppFixedColors.momentTrack,
        'momentGhost': AppFixedColors.momentGhost,
      },
      'Sabit: toast': {
        'inverseSurface': AppFixedColors.inverseSurface,
        'inverseText': AppFixedColors.inverseText,
        'inverseAction': AppFixedColors.inverseAction,
        'inverseSuccess': AppFixedColors.inverseSuccess,
        'inverseError': AppFixedColors.inverseError,
      },
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final group in groups.entries) ...[
          Padding(
            padding: const EdgeInsets.only(
              top: AppSpacing.md,
              bottom: AppSpacing.xs,
            ),
            child: Text(
              group.key,
              style: context.text.overline.copyWith(color: c.textSecondary),
            ),
          ),
          for (final color in group.value.entries)
            Padding(
              key: ValueKey('swatch-${color.key}'),
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: Row(
                children: [
                  DecoratedBox(
                    decoration: AppRadius.decoration(
                      radius: AppRadius.sm,
                      color: color.value,
                      side: BorderSide(color: c.borderControl),
                    ),
                    child: const SizedBox.square(dimension: AppSpacing.huge),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(color.key, style: context.text.label),
                        _Caption(hex(color.value)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------- Tipografi

class _TypographySection extends StatelessWidget {
  const _TypographySection();

  @override
  Widget build(BuildContext context) {
    final t = context.text;
    final samples = <(String, TextStyle, String)>[
      ('display', t.display, 'Hepiniz anlaştınız.'),
      ('h1', t.h1, 'Cuma akşamı'),
      ('h2', t.h2, 'Sonuçlar hazır'),
      ('h3', t.h3, 'Trattoria Lume'),
      ('title', t.title, 'Trattoria Lume'),
      (
        'body',
        t.body,
        'Arkadaşlarınla nereye gideceğinize birlikte karar verin.',
      ),
      ('bodySmall', t.bodySmall, 'Dört kişiden üçü bu mekanı sevdi.'),
      ('label', t.label, 'Tercihlerim'),
      ('button', t.button, 'Oda oluştur'),
      ('buttonSmall', t.buttonSmall, 'Dürt'),
      ('caption', t.caption.tabular, '4,6 · İtalyan · ₺₺ · 1,2 km · %80'),
      ('overline', t.overline, 'Bekleyenler'),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final (name, style, sample) in samples)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Caption(
                  '$name · ${style.fontSize!.toStringAsFixed(0)}/'
                  '${(style.height! * style.fontSize!).round()} · '
                  '${style.fontWeight!.value} · ${style.letterSpacing}',
                ),
                const SizedBox(height: AppSpacing.xxs),
                if (name == 'display' || name == 'h1')
                  ClampedTextScale.display(child: Text(sample, style: style))
                else
                  Text(sample, style: style),
              ],
            ),
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------- Spacing

class _SpacingSection extends StatelessWidget {
  const _SpacingSection();

  @override
  Widget build(BuildContext context) {
    const tokens = <String, double>{
      'xxs': AppSpacing.xxs,
      'xs': AppSpacing.xs,
      'sm': AppSpacing.sm,
      'md': AppSpacing.md,
      'lg': AppSpacing.lg,
      'xl': AppSpacing.xl,
      'xxl': AppSpacing.xxl,
      'xxxl': AppSpacing.xxxl,
      'huge': AppSpacing.huge,
      'giant': AppSpacing.giant,
    };
    return Column(
      children: [
        for (final t in tokens.entries)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: Row(
              children: [
                SizedBox(
                  width: AppSpacing.giant + AppSpacing.xl,
                  child: Text(
                    '${t.key} ${t.value.toStringAsFixed(0)}',
                    style: context.text.label,
                  ),
                ),
                ColoredBox(
                  color: context.colors.brandMuted,
                  child: SizedBox(width: t.value, height: AppSpacing.md),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------- Radius

class _RadiusSection extends StatelessWidget {
  const _RadiusSection();

  @override
  Widget build(BuildContext context) {
    const tokens = <String, double>{
      'xs': AppRadius.xs,
      'sm': AppRadius.sm,
      'md': AppRadius.md,
      'lg': AppRadius.lg,
      'xl': AppRadius.xl,
      'pill': AppRadius.pill,
    };
    final c = context.colors;
    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.md,
      children: [
        for (final t in tokens.entries)
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DecoratedBox(
                decoration: AppRadius.decoration(
                  radius: t.value,
                  color: c.surfaceMuted,
                  side: BorderSide(color: c.borderControl),
                ),
                child: SizedBox(
                  width: t.key == 'pill'
                      ? AppSpacing.giant + AppSpacing.xl
                      : AppSpacing.giant,
                  height: t.key == 'pill'
                      ? AppSpacing.touchTarget
                      : AppSpacing.giant,
                ),
              ),
              const SizedBox(height: AppSpacing.xxs),
              _Caption('${t.key} ${t.value.toStringAsFixed(0)}'),
            ],
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------- Elevation

class _ElevationSection extends StatelessWidget {
  const _ElevationSection();

  @override
  Widget build(BuildContext context) {
    final e = context.elevation;
    final c = context.colors;
    final levels = {'E1 kart': e.e1, 'E2 toast': e.e2, 'E3 sheet': e.e3};
    return Wrap(
      spacing: AppSpacing.lg,
      runSpacing: AppSpacing.lg,
      children: [
        for (final l in levels.entries)
          DecoratedBox(
            decoration: AppRadius.decoration(
              radius: AppRadius.lg,
              color: c.surface,
              elevation: l.value,
            ),
            child: SizedBox(
              width: AppSpacing.giant + AppSpacing.xxxl,
              height: AppSpacing.giant + AppSpacing.xl,
              child: Center(child: Text(l.key, style: context.text.label)),
            ),
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------- İkonlar

class _IconSection extends StatelessWidget {
  const _IconSection();

  @override
  Widget build(BuildContext context) {
    const icons = <String, IconData>{
      'share': AppIcons.share,
      'undo': AppIcons.undo,
      'check': AppIcons.check,
      'close': AppIcons.close,
      'heart': AppIcons.heart,
      'heartFill': AppIcons.heartFill,
      'prohibit': AppIcons.prohibit,
      'search': AppIcons.search,
      'plus': AppIcons.plus,
      'minus': AppIcons.minus,
      'back': AppIcons.back,
      'chevronRight': AppIcons.chevronRight,
      'upDown': AppIcons.upDown,
      'link': AppIcons.link,
      'copy': AppIcons.copy,
      'warning': AppIcons.warning,
      'info': AppIcons.info,
      'star': AppIcons.star,
      'starFill': AppIcons.starFill,
      'map': AppIcons.map,
      'userPlus': AppIcons.userPlus,
      'wifiOff': AppIcons.wifiOff,
    };
    const sizes = [
      AppIconSize.s14,
      AppIconSize.s16,
      AppIconSize.s20,
      AppIconSize.s24,
      AppIconSize.s32,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: AppSpacing.lg,
          runSpacing: AppSpacing.md,
          children: [
            for (final i in icons.entries)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    i.value,
                    size: AppIconSize.s24,
                    color: context.colors.textPrimary,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Flexible(child: Text(i.key, style: context.text.bodySmall)),
                ],
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        Wrap(
          spacing: AppSpacing.lg,
          runSpacing: AppSpacing.xs,
          crossAxisAlignment: WrapCrossAlignment.end,
          children: [
            for (final s in sizes)
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    AppIcons.heartFill,
                    size: s,
                    color: context.colors.brand,
                  ),
                  _Caption(s.toStringAsFixed(0)),
                ],
              ),
          ],
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------- Hareket

class _MotionSection extends StatelessWidget {
  const _MotionSection();

  @override
  Widget build(BuildContext context) {
    final m = context.motion;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Caption(
          'fast ${m.fast.inMilliseconds} · standard ${m.standard.inMilliseconds} · '
          'emphasis ${m.emphasis.inMilliseconds} · expressive ${m.expressive.inMilliseconds} ms'
          '${m.reduceMotion ? ' · Reduce Motion açık' : ''}',
        ),
        const SizedBox(height: AppSpacing.xs),
        Text('Eğriler (dokun: oynat)', style: context.text.label),
        const _CurveDemo('enter', AppMotion.enter),
        const _CurveDemo('exit', AppMotion.exit),
        const _CurveDemo('move', AppMotion.move),
        const SizedBox(height: AppSpacing.md),
        Text('Spring\'ler (dokun: oynat)', style: context.text.label),
        _SpringDemo('snappy', m.springSnappy),
        _SpringDemo('standard', m.springStandard),
        _SpringDemo('bouncy', m.springBouncy),
      ],
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot();

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: AppRadius.decoration(
      radius: AppRadius.pill,
      color: context.colors.brand,
    ),
    child: const SizedBox.square(dimension: AppSpacing.xl),
  );
}

class _CurveDemo extends StatefulWidget {
  const _CurveDemo(this.name, this.curve);

  final String name;
  final Curve curve;

  @override
  State<_CurveDemo> createState() => _CurveDemoState();
}

class _CurveDemoState extends State<_CurveDemo> {
  bool _end = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => setState(() => _end = !_end),
      child: Row(
        children: [
          SizedBox(
            width: AppSpacing.giant,
            child: Text(widget.name, style: context.text.bodySmall),
          ),
          Expanded(
            child: SizedBox(
              height: AppSpacing.touchTarget,
              child: AnimatedAlign(
                alignment: _end ? Alignment.centerRight : Alignment.centerLeft,
                duration: context.motion.expressive,
                curve: widget.curve,
                child: const _Dot(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SpringDemo extends StatefulWidget {
  const _SpringDemo(this.name, this.spring);

  final String name;
  final SpringDescription spring;

  @override
  State<_SpringDemo> createState() => _SpringDemoState();
}

class _SpringDemoState extends State<_SpringDemo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController.unbounded(
    vsync: this,
  );
  bool _end = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    _end = !_end;
    _controller.animateWith(
      SpringSimulation(
        widget.spring,
        _controller.value,
        _end ? 1 : 0,
        _controller.velocity,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _toggle,
      child: Row(
        children: [
          SizedBox(
            width: AppSpacing.giant,
            child: Text(widget.name, style: context.text.bodySmall),
          ),
          Expanded(
            child: SizedBox(
              height: AppSpacing.touchTarget,
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) => Align(
                  alignment: Alignment(_controller.value * 2 - 1, 0),
                  child: child,
                ),
                child: const _Dot(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------- Haptik

class _HapticsSection extends StatelessWidget {
  const _HapticsSection();

  @override
  Widget build(BuildContext context) {
    final actions = <String, VoidCallback>{
      'selection': AppHaptics.selection,
      'light': AppHaptics.light,
      'medium': AppHaptics.medium,
      'rigid': AppHaptics.rigid,
      'success': AppHaptics.success,
      'error': AppHaptics.error,
    };
    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      children: [
        for (final a in actions.entries)
          FilledButton.tonal(onPressed: a.value, child: Text(a.key)),
      ],
    );
  }
}

// ---------------------------------------------------------------- Buton

class _ButtonSection extends StatelessWidget {
  const _ButtonSection();

  @override
  Widget build(BuildContext context) {
    void noop() {}
    Widget group(
      String name,
      Widget Function(
        String,
        VoidCallback?, {
        IconData? icon,
        bool loading,
        AppButtonSize size,
      })
      build,
    ) {
      return Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              name,
              style: context.text.overline.copyWith(
                color: context.colors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            build('Oda oluştur', noop, size: AppButtonSize.large),
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                build('Medium', noop, size: AppButtonSize.medium),
                build(
                  'İkonlu',
                  noop,
                  icon: AppIcons.share,
                  size: AppButtonSize.medium,
                ),
                build('Pasif', null, size: AppButtonSize.medium),
                build(
                  'Yükleniyor',
                  noop,
                  loading: true,
                  size: AppButtonSize.medium,
                ),
                build('Small', noop, size: AppButtonSize.small),
                build(
                  'İkonlu',
                  noop,
                  icon: AppIcons.undo,
                  size: AppButtonSize.small,
                ),
              ],
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        group(
          'primary',
          (l, p, {icon, loading = false, size = AppButtonSize.large}) =>
              AppButton.primary(
                label: l,
                onPressed: p,
                icon: icon,
                isLoading: loading,
                size: size,
              ),
        ),
        group(
          'secondary',
          (l, p, {icon, loading = false, size = AppButtonSize.large}) =>
              AppButton.secondary(
                label: l,
                onPressed: p,
                icon: icon,
                isLoading: loading,
                size: size,
              ),
        ),
        group(
          'tertiary',
          (l, p, {icon, loading = false, size = AppButtonSize.large}) =>
              AppButton.tertiary(
                label: l,
                onPressed: p,
                icon: icon,
                isLoading: loading,
                size: size,
              ),
        ),
        group(
          'destructive',
          (l, p, {icon, loading = false, size = AppButtonSize.large}) =>
              AppButton.destructive(
                label: l,
                onPressed: p,
                icon: icon,
                isLoading: loading,
                size: size,
              ),
        ),
        group(
          'destructiveStrong',
          (l, p, {icon, loading = false, size = AppButtonSize.large}) =>
              AppButton.destructiveStrong(
                label: l,
                onPressed: p,
                icon: icon,
                isLoading: loading,
                size: size,
              ),
        ),
        Text(
          'moment (momentBg zemininde)',
          style: context.text.overline.copyWith(
            color: context.colors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        DecoratedBox(
          decoration: AppRadius.decoration(
            radius: AppRadius.lg,
            color: AppFixedColors.momentBg,
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              children: [
                AppButton.moment(label: 'Yol tarifi al', onPressed: noop),
                const SizedBox(height: AppSpacing.xs),
                AppButton.momentGhost(label: 'Gruba paylaş', onPressed: noop),
                const SizedBox(height: AppSpacing.xs),
                AppButton.momentText(label: 'Kapat', onPressed: noop),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------- İkon butonu

class _IconButtonSection extends StatelessWidget {
  const _IconButtonSection();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    void noop() {}
    Widget label(String text) => Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Text(
        text,
        style: context.text.overline.copyWith(color: c.textSecondary),
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        label('plain (nav bar) · normal, pasif'),
        Row(
          children: [
            AppIconButton.plain(
              icon: AppIcons.back,
              semanticLabel: 'Geri',
              onPressed: noop,
            ),
            AppIconButton.plain(
              icon: AppIcons.share,
              semanticLabel: 'Paylaş',
              onPressed: noop,
            ),
            const AppIconButton.plain(
              icon: AppIcons.plus,
              semanticLabel: 'Ekle',
              onPressed: null,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        label('soft · normal, pasif'),
        Row(
          children: [
            AppIconButton.soft(
              icon: AppIcons.undo,
              semanticLabel: 'Geri al',
              onPressed: noop,
            ),
            AppIconButton.soft(
              icon: AppIcons.copy,
              semanticLabel: 'Kopyala',
              onPressed: noop,
            ),
            const AppIconButton.soft(
              icon: AppIcons.close,
              semanticLabel: 'Kapat',
              onPressed: null,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        label('media (fotoğraf üstü)'),
        DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: AppRadius.all(AppRadius.lg),
            gradient: LinearGradient(
              colors: [c.avatarSage, c.avatarMist, c.avatarRose],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xs),
            child: Row(
              children: [
                AppIconButton.media(
                  icon: AppIcons.back,
                  semanticLabel: 'Geri',
                  onPressed: noop,
                ),
                const Spacer(),
                AppIconButton.media(
                  icon: AppIcons.heart,
                  semanticLabel: 'Beğen',
                  onPressed: noop,
                ),
                AppIconButton.media(
                  icon: AppIcons.share,
                  semanticLabel: 'Paylaş',
                  onPressed: noop,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------- Logo

class _LogoSection extends StatelessWidget {
  const _LogoSection();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    Widget panel(String name, Color? background, Widget child) => Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            style: context.text.overline.copyWith(color: c.textSecondary),
          ),
          const SizedBox(height: AppSpacing.xs),
          DecoratedBox(
            decoration: AppRadius.decoration(
              radius: AppRadius.lg,
              color: background,
              side: BorderSide(color: c.border),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: child,
            ),
          ),
        ],
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        panel(
          'auto (temaya göre) · wordmark',
          null,
          const AppLogo.auto(wordmark: true),
        ),
        panel(
          'twoTone · canvas/surface üstünde',
          c.surface,
          const Wrap(
            spacing: AppSpacing.xl,
            runSpacing: AppSpacing.md,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              AppLogo(variant: AppLogoVariant.twoTone),
              AppLogo(variant: AppLogoVariant.twoTone, wordmark: true),
            ],
          ),
        ),
        panel(
          'ink · tek renk',
          c.surface,
          const AppLogo(variant: AppLogoVariant.ink, wordmark: true),
        ),
        panel(
          'cream · momentBg üstünde',
          AppFixedColors.momentBg,
          const AppLogo(variant: AppLogoVariant.cream, wordmark: true),
        ),
        panel(
          'plumLight · koyu tema',
          AppColors.dark.canvas,
          const AppLogo(variant: AppLogoVariant.plumLight, wordmark: true),
        ),
        panel(
          'boyutlar: işaret yüksekliği 20, 32, 48, 64, 88',
          c.surface,
          const Wrap(
            spacing: AppSpacing.lg,
            runSpacing: AppSpacing.md,
            crossAxisAlignment: WrapCrossAlignment.end,
            children: [
              AppLogo(variant: AppLogoVariant.twoTone, size: AppIconSize.s20),
              AppLogo(variant: AppLogoVariant.twoTone, size: AppIconSize.s32),
              AppLogo(variant: AppLogoVariant.twoTone, size: AppSpacing.huge),
              AppLogo(variant: AppLogoVariant.twoTone, size: AppSpacing.giant),
              AppLogo(
                variant: AppLogoVariant.twoTone,
                size: AppSpacing.giant + AppSpacing.xl,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------- Metin alanı

class _TextFieldSection extends StatefulWidget {
  const _TextFieldSection();

  @override
  State<_TextFieldSection> createState() => _TextFieldSectionState();
}

class _TextFieldSectionState extends State<_TextFieldSection> {
  final _filled = TextEditingController(text: 'Cuma akşamı');
  final _email = TextEditingController(text: 'ayse@');

  @override
  void dispose() {
    _filled.dispose();
    _email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const gap = SizedBox(height: AppSpacing.lg);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppTextField(label: 'Oda adı', hintText: 'Örn. Cuma akşamı'),
        gap,
        AppTextField(
          label: 'Dolu (odakla: temizle ikonu)',
          controller: _filled,
        ),
        gap,
        AppTextField(
          label: 'E-posta',
          controller: _email,
          keyboardType: TextInputType.emailAddress,
          errorText: 'Geçerli bir e-posta adresi yaz.',
        ),
        gap,
        const AppTextField(
          label: 'Pasif',
          hintText: 'Düzenlenemez',
          enabled: false,
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------- Arama alanı

class _SearchFieldSection extends StatelessWidget {
  const _SearchFieldSection();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppSearchField(hintText: 'Mekan ara'),
        SizedBox(height: AppSpacing.md),
        AppSearchField(hintText: 'Pasif', enabled: false),
      ],
    );
  }
}
