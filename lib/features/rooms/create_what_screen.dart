import 'package:flutter/material.dart';

import '../../app/app_router.dart';
import '../../app/app_scope.dart';
import '../../core/design_system/components/content/app_card.dart';
import '../../core/design_system/components/feedback/app_empty_state.dart';
import '../../core/design_system/components/feedback/app_skeleton.dart';
import '../../core/design_system/foundations/app_icons.dart';
import '../../core/design_system/foundations/app_pressable.dart';
import '../../core/design_system/foundations/context_extensions.dart';
import '../../core/design_system/tokens/app_radius.dart';
import '../../core/design_system/tokens/app_spacing.dart';
import '../../core/domain/room_catalog.dart';
import '../../l10n/app_localizations.dart';
import 'room_icons.dart';
import 'widgets/create_scaffold.dart';

/// D1 · 1. adım "Ne yapıyorsunuz?" (SCREENS D1 `CreateWhat`): tema kartları + kategori
/// ızgarası. Bir seçeneğe dokununca doğrudan 2. adıma geçilir (Devam butonu yok).
class CreateWhatScreen extends StatefulWidget {
  const CreateWhatScreen({super.key});

  @override
  State<CreateWhatScreen> createState() => _CreateWhatScreenState();
}

class _CreateWhatScreenState extends State<CreateWhatScreen> {
  RoomCatalog? _catalog;
  bool _failed = false;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _load();
  }

  Future<void> _load() async {
    setState(() => _failed = false);
    try {
      final catalog = await AppScope.of(context).rooms.loadCatalog();
      if (mounted) setState(() => _catalog = catalog);
    } on Object {
      if (mounted) setState(() => _failed = true);
    }
  }

  void _next({required RoomCategory category, RoomWhen? when}) {
    AppRoutes.pushCreateDetails(
      context,
      CreateDetailsArgs(
        category: category,
        when: when ?? RoomWhen.tonight,
        catalog: _catalog!,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final catalog = _catalog;
    return CreateScaffold(
      progress: 0.5,
      onClose: () => Navigator.of(context).maybePop(),
      child: _failed
          ? Align(
              alignment: const Alignment(0, -0.35),
              child: AppEmptyState.error(
                title: l10n.homeLoadFailedTitle,
                message: l10n.homeLoadFailedBody,
                actionLabel: l10n.homeRetry,
                onAction: _load,
              ),
            )
          : catalog == null
          ? const _Skeleton()
          : _Content(catalog: catalog, onPick: _next),
    );
  }
}

class _Content extends StatelessWidget {
  const _Content({required this.catalog, required this.onPick});

  final RoomCatalog catalog;
  final void Function({required RoomCategory category, RoomWhen? when}) onPick;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListView(
      padding: const EdgeInsets.only(
        top: AppSpacing.xl + AppSpacing.xxs,
        bottom: AppSpacing.xxl,
      ),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenPadding,
          ),
          child: Semantics(
            header: true,
            child: Text(l10n.createWhatTitle, style: context.text.h1),
          ),
        ),
        if (catalog.themes.isNotEmpty) ...[
          _Heading(l10n.createThemesTitle, top: AppSpacing.xl),
          _Themes(
            themes: catalog.themes,
            onPick: (theme) {
              final category = catalog.category(theme.categoryId);
              if (category != null) {
                onPick(category: category, when: theme.when);
              }
            },
          ),
        ],
        _Heading(
          l10n.createCategoriesTitle,
          top: AppSpacing.xl + AppSpacing.xxs,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenPadding,
          ),
          child: _Grid(
            categories: catalog.categories,
            onPick: (category) => onPick(category: category),
          ),
        ),
      ],
    );
  }
}

class _Heading extends StatelessWidget {
  const _Heading(this.text, {required this.top});

  final String text;
  final double top;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.screenPadding,
        top,
        AppSpacing.screenPadding,
        AppSpacing.sm,
      ),
      child: Semantics(
        header: true,
        child: Text(text, style: context.text.title),
      ),
    );
  }
}

/// Yatay kaydırılan tema kartları; avatar tintleriyle renklenir.
class _Themes extends StatelessWidget {
  const _Themes({required this.themes, required this.onPick});

  final List<RoomTheme> themes;
  final ValueChanged<RoomTheme> onPick;

  static const double _width = 156;
  static const double _height = 124;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = context.text;
    // Büyük yazıda kart yüksekliği yazıyla birlikte büyür.
    final height = MediaQuery.textScalerOf(context)
        .scale(_height)
        .clamp(_height, _height * 2);
    return SizedBox(
      height: height,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.screenPadding,
        ),
        itemCount: themes.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, i) {
          final theme = themes[i];
          return AppPressable(
            onPressed: () => onPick(theme),
            semanticLabel: theme.label,
            minWidth: _width,
            builder: (context, _) => DecoratedBox(
              decoration: AppRadius.decoration(
                radius: AppRadius.lg,
                color: c.avatarTints[theme.tintIndex % c.avatarTints.length],
              ),
              child: SizedBox(
                width: _width,
                height: height,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Icon(
                        RoomIcons.theme(theme.id),
                        size: AppIconSize.s24,
                        color: c.textPrimary,
                      ),
                      Text(
                        theme.label,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: text.title.copyWith(color: c.textPrimary),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// İki sütunlu kategori ızgarası. Sayıya bağımlı değil: satırlar [Wrap] ile akar.
class _Grid extends StatelessWidget {
  const _Grid({required this.categories, required this.onPick});

  final List<RoomCategory> categories;
  final ValueChanged<RoomCategory> onPick;

  static const double _minHeight = 64;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return LayoutBuilder(
      builder: (context, box) {
        final width = (box.maxWidth - AppSpacing.sm) / 2;
        return Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final category in categories)
              SizedBox(
                width: width,
                child: AppCard(
                  padding: EdgeInsets.zero,
                  onPressed: () => onPick(category),
                  semanticLabel: category.label,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: _minHeight),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            RoomIcons.category(category.id),
                            size: AppIconSize.s24,
                            color: c.brand,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              category.label,
                              style: context.text.title,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _Skeleton extends StatelessWidget {
  const _Skeleton();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.screenPadding,
        AppSpacing.xl,
        AppSpacing.screenPadding,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppSkeleton(height: 38, radius: AppRadius.xs),
          SizedBox(height: AppSpacing.xl),
          AppSkeleton(height: 124, radius: AppRadius.lg),
          SizedBox(height: AppSpacing.xl),
          AppSkeleton(height: 64, radius: AppRadius.lg),
          SizedBox(height: AppSpacing.sm),
          AppSkeleton(height: 64, radius: AppRadius.lg),
        ],
      ),
    );
  }
}

/// 2. adıma taşınan seçimler.
class CreateDetailsArgs {
  const CreateDetailsArgs({
    required this.category,
    required this.when,
    required this.catalog,
  });

  final RoomCategory category;
  final RoomWhen when;
  final RoomCatalog catalog;
}
