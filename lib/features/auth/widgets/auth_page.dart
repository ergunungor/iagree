import 'package:flutter/material.dart';

import '../../../core/design_system/components/buttons/app_icon_button.dart';
import '../../../core/design_system/foundations/app_icons.dart';
import '../../../core/design_system/foundations/clamped_text_scale.dart';
import '../../../core/design_system/foundations/context_extensions.dart';
import '../../../core/design_system/tokens/app_spacing.dart';
import '../../../l10n/app_localizations.dart';

/// Giriş akışı ekranlarının ortak iskeleti (SCREENS A3–A5): isteğe bağlı geri, `h1` başlık,
/// açıklama, içerik ve altta sabit eylem. İçerik büyük yazıda kayar; eylem klavyenin hemen
/// üstünde kalır.
class AuthPage extends StatelessWidget {
  const AuthPage({
    super.key,
    required this.title,
    required this.children,
    this.subtitle,
    this.onBack,
    this.bottom,
    this.topPadding = 0,
  });

  final String title;

  /// Başlığın altındaki açıklama; zengin metin için widget.
  final Widget? subtitle;
  final List<Widget> children;

  /// Verilirse sol üstte geri.
  final VoidCallback? onBack;

  /// Altta sabit eylem (Primary buton vb.).
  final Widget? bottom;

  /// Geri butonu olmayan ekranlarda (profil) üst boşluk.
  final double topPadding;

  /// İkonun ekran kenarından [AppSpacing.screenPadding] içeride durması için geri satırının
  /// yan boşluğu.
  static const double _backEdge =
      AppSpacing.screenPadding - (AppSpacing.touchTarget - AppIconSize.s24) / 2;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = context.colors;
    return Scaffold(
      backgroundColor: c.canvas,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverFillRemaining(
              hasScrollBody: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (onBack != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: _backEdge,
                      ),
                      child: Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: AppIconButton.plain(
                          icon: AppIcons.back,
                          semanticLabel: l10n.commonBack,
                          onPressed: onBack,
                        ),
                      ),
                    )
                  else
                    SizedBox(height: topPadding),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.screenPadding,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: AppSpacing.md),
                          Semantics(
                            header: true,
                            child: ClampedTextScale.display(
                              child: Text(title, style: context.text.h1),
                            ),
                          ),
                          if (subtitle != null) ...[
                            const SizedBox(height: AppSpacing.xs),
                            subtitle!,
                          ],
                          ...children,
                          const Spacer(),
                          if (bottom != null) ...[
                            const SizedBox(height: AppSpacing.xl),
                            bottom!,
                          ],
                          const SizedBox(height: AppSpacing.xs),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Başlık altı açıklama metni (`body`, `textSecondary`).
class AuthSubtitle extends StatelessWidget {
  const AuthSubtitle(this.text, {super.key}) : span = null;

  const AuthSubtitle.rich(this.span, {super.key}) : text = null;

  final String? text;
  final InlineSpan? span;

  @override
  Widget build(BuildContext context) {
    final style = context.text.body.copyWith(
      color: context.colors.textSecondary,
    );
    return span == null
        ? Text(text!, style: style)
        : Text.rich(span!, style: style);
  }
}
