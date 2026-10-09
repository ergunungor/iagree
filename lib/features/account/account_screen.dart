import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../app/app_info.dart';
import '../../app/app_router.dart';
import '../../app/user_image.dart';
import '../../app/app_links.dart';
import '../../app/link_actions.dart';
import '../../app/app_scope.dart';
import '../../core/data/mock/mock_rooms_repository.dart';
import '../../core/design_system/components/content/app_list_group.dart';
import '../../core/design_system/components/feedback/app_alert.dart';
import '../../core/design_system/components/feedback/app_sheet.dart';
import '../../core/design_system/components/buttons/app_button.dart';
import '../../core/design_system/components/buttons/app_icon_button.dart';
import '../../core/design_system/components/people/app_avatar.dart';
import '../../core/design_system/foundations/app_icons.dart';
import '../../core/design_system/foundations/context_extensions.dart';
import '../../core/design_system/gallery/design_system_gallery.dart';
import '../../core/design_system/tokens/app_spacing.dart';
import '../../l10n/app_localizations.dart';

/// C2 · Profil (SCREENS C2): avatar, isim, e-posta; ayar grupları; çıkış ve hesap silme.
class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  /// "Gizlilik ve koşullar": iki bağlantı. Seçilen eylem sheet kapandıktan sonra çalışır.
  Future<void> _legal(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final uri = await AppSheet.show<Uri>(
      context,
      title: l10n.accountPrivacy,
      builder: (sheetContext) => AppListGroup(
        children: [
          AppListRow(
            title: l10n.accountTerms,
            showsChevron: true,
            onPressed: () => Navigator.of(sheetContext).pop(AppLinks.terms),
          ),
          AppListRow(
            title: l10n.accountPrivacyPolicy,
            showsChevron: true,
            onPressed: () => Navigator.of(sheetContext).pop(AppLinks.privacy),
          ),
        ],
      ),
    );
    if (uri != null && context.mounted) await openExternal(context, uri);
  }

  Future<void> _chooseTheme(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final settings = AppScope.of(context).settings;
    final labels = {
      ThemeMode.system: l10n.accountThemeSystem,
      ThemeMode.light: l10n.accountThemeLight,
      ThemeMode.dark: l10n.accountThemeDark,
    };
    return AppSheet.show<void>(
      context,
      title: l10n.accountAppearance,
      builder: (sheetContext) => ListenableBuilder(
        listenable: settings,
        builder: (context, _) => AppListGroup(
          children: [
            for (final mode in ThemeMode.values)
              AppListRow(
                title: labels[mode]!,
                selected: settings.themeMode == mode,
                onPressed: () {
                  settings.setThemeMode(mode);
                  Navigator.of(sheetContext).pop();
                },
              ),
          ],
        ),
      ),
    );
  }

  /// Profil ekranı kök ekranın üstünde durur; kök karşılamaya dönerken yığın önce temizlenir.
  Future<void> _signOut(BuildContext context) {
    final session = AppScope.of(context).session;
    Navigator.of(context).popUntil((route) => route.isFirst);
    return session.signOut();
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final session = AppScope.of(context).session;
    final navigator = Navigator.of(context);
    final confirmed = await AppAlert.show(
      context,
      title: l10n.accountDeleteTitle,
      message: l10n.accountDeleteMessage,
      actionLabel: l10n.accountDeleteConfirm,
    );
    if (!confirmed) return;
    navigator.popUntil((route) => route.isFirst);
    await session.deleteAccount();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scope = AppScope.of(context);

    final themeLabels = {
      ThemeMode.system: l10n.accountThemeSystem,
      ThemeMode.light: l10n.accountThemeLight,
      ThemeMode.dark: l10n.accountThemeDark,
    };

    return ListenableBuilder(
      listenable: scope.session,
      builder: (context, _) => _body(context, scope, themeLabels),
    );
  }

  Widget _body(
    BuildContext context,
    AppScope scope,
    Map<ThemeMode, String> themeLabels,
  ) {
    final l10n = AppLocalizations.of(context);
    final c = context.colors;
    final text = context.text;
    final user = scope.session.user;
    return Scaffold(
      backgroundColor: c.canvas,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxs),
              child: Row(
                children: [
                  AppIconButton.plain(
                    icon: AppIcons.back,
                    semanticLabel: l10n.commonBack,
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                  const Spacer(),
                  AppButton.tertiary(
                    label: l10n.accountEdit,
                    size: AppButtonSize.small,
                    fullWidth: false,
                    onPressed: () => AppRoutes.pushEditProfile(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screenPadding,
                  AppSpacing.sm,
                  AppSpacing.screenPadding,
                  AppSpacing.xxl,
                ),
                children: [
                  Column(
                    children: [
                      AppAvatar(
                        userId: user?.id ?? '',
                        name: user?.name ?? '',
                        image: userImage(user),
                        size: AppAvatarSize.xl,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Semantics(
                        header: true,
                        child: Text(
                          user?.name ?? '',
                          textAlign: TextAlign.center,
                          style: text.h1,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        user?.email ?? '',
                        textAlign: TextAlign.center,
                        style: text.bodySmall.copyWith(color: c.textSecondary),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  AppListGroup(
                    children: [
                      AppListRow(
                        title: l10n.accountNotifications,
                        showsChevron: true,
                        onPressed: () =>
                            AppRoutes.pushNotificationSettings(context),
                      ),
                      AppListRow(
                        title: l10n.accountAppearance,
                        trailing: ListenableBuilder(
                          listenable: scope.settings,
                          builder: (context, _) => ExcludeSemantics(
                            child: Text(
                              themeLabels[scope.settings.themeMode]!,
                              style: text.body.copyWith(color: c.textSecondary),
                            ),
                          ),
                        ),
                        showsChevron: true,
                        onPressed: () => _chooseTheme(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  AppListGroup(
                    children: [
                      AppListRow(
                        title: l10n.accountPrivacy,
                        showsChevron: true,
                        onPressed: () => _legal(context),
                      ),
                      AppListRow(
                        title: l10n.accountContact,
                        showsChevron: true,
                        onPressed: () =>
                            openExternal(context, AppLinks.support),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  AppListGroup(
                    children: [
                      AppListRow(
                        title: l10n.accountSignOut,
                        onPressed: () => _signOut(context),
                      ),
                      AppListRow(
                        title: l10n.accountDelete,
                        destructive: true,
                        onPressed: () => _confirmDelete(context),
                      ),
                    ],
                  ),
                  if (kDebugMode) ...[
                    const SizedBox(height: AppSpacing.xl),
                    _DebugGroup(),
                  ],
                  const SizedBox(height: AppSpacing.xl),
                  Text(
                    l10n.accountVersion(AppInfo.version),
                    textAlign: TextAlign.center,
                    style: text.caption.copyWith(color: c.textTertiary),
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

/// Yalnızca debug derlemede: oda veri senaryosu ve tasarım galerisi. Yerelleştirilmez,
/// yayına girmez (`kDebugMode` derleme zamanında ağacı keser).
class _DebugGroup extends StatelessWidget {
  static const Map<MockRoomsScenario, String> _labels = {
    MockRoomsScenario.mixed: 'Karışık odalar',
    MockRoomsScenario.waitingOnly: 'Yalnızca bekleyen',
    MockRoomsScenario.empty: 'Hiç oda yok',
    MockRoomsScenario.failing: 'Yükleme hatası',
  };

  Future<void> _pickScenario(BuildContext context) {
    final rooms = AppScope.of(context).rooms;
    final repo = rooms.repository;
    if (repo is! MockRoomsRepository) return Future.value();
    return AppSheet.show<void>(
      context,
      title: 'Oda senaryosu (debug)',
      builder: (sheetContext) => AppListGroup(
        children: [
          for (final entry in _labels.entries)
            AppListRow(
              title: entry.value,
              selected: repo.scenario == entry.key,
              onPressed: () {
                repo.scenario = entry.key;
                Navigator.of(sheetContext).pop();
                rooms.load();
              },
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppListGroup(
      children: [
        AppListRow(
          title: 'Oda senaryosu (debug)',
          showsChevron: true,
          onPressed: () => _pickScenario(context),
        ),
        AppListRow(
          title: 'Tasarım galerisi (debug)',
          showsChevron: true,
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const DesignSystemGallery(),
            ),
          ),
        ),
      ],
    );
  }
}
