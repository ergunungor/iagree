import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/app_links.dart';
import '../../app/app_scope.dart';
import '../../app/link_actions.dart';
import '../../app/platform_services.dart';
import '../../app/settings_controller.dart';
import '../../core/design_system/components/buttons/app_button.dart';
import '../../core/design_system/components/buttons/app_icon_button.dart';
import '../../core/design_system/components/content/app_card.dart';
import '../../core/design_system/components/content/app_list_group.dart';
import '../../core/design_system/components/selection/app_toggle.dart';
import '../../core/design_system/foundations/app_icons.dart';
import '../../core/design_system/foundations/context_extensions.dart';
import '../../core/design_system/tokens/app_spacing.dart';
import '../../l10n/app_localizations.dart';

/// Profil → Bildirimler: konu bazlı açma/kapama. Sistem izni kapalıysa üstte uyarı kartı ve
/// "Ayarları aç" çıkar; bir konu açılırken izin yoksa sistem izni istenir. Ayarlar'dan
/// dönünce durum yeniden okunur.
class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen>
    with WidgetsBindingObserver {
  NotificationAccess? _access;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _refresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refresh();
  }

  Future<void> _refresh() async {
    final access = await AppScope.of(context).notifications.status();
    if (mounted) setState(() => _access = access);
  }

  Future<void> _toggle(NotificationTopic topic, bool on) async {
    final scope = AppScope.of(context);
    // Ayar anında uygulanır; diske yazım arka planda sürer.
    unawaited(scope.settings.setTopic(topic, on));
    if (on && _access != NotificationAccess.granted) {
      final access = await scope.notifications.request();
      if (mounted) setState(() => _access = access);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = context.colors;
    final text = context.text;
    final settings = AppScope.of(context).settings;
    final off = _access == NotificationAccess.denied;

    final topics = <(NotificationTopic, String, String)>[
      (NotificationTopic.turn, l10n.notifTurn, l10n.notifTurnHint),
      (NotificationTopic.results, l10n.notifResults, l10n.notifResultsHint),
      (NotificationTopic.decision, l10n.notifDecision, l10n.notifDecisionHint),
      (NotificationTopic.nudge, l10n.notifNudge, l10n.notifNudgeHint),
    ];

    return Scaffold(
      backgroundColor: c.canvas,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxs),
                child: AppIconButton.plain(
                  icon: AppIcons.back,
                  semanticLabel: l10n.commonBack,
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screenPadding,
                  AppSpacing.xxs,
                  AppSpacing.screenPadding,
                  AppSpacing.xxl,
                ),
                children: [
                  Semantics(
                    header: true,
                    child: Text(l10n.notifTitle, style: text.h1),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  if (off) ...[
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Semantics(
                            header: true,
                            child: Text(l10n.notifOffTitle, style: text.title),
                          ),
                          const SizedBox(height: AppSpacing.xxs),
                          Text(
                            l10n.notifOffBody,
                            style: text.bodySmall.copyWith(
                              color: c.textSecondary,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          AppButton.secondary(
                            label: l10n.notifOpenSettings,
                            onPressed: () =>
                                openExternal(context, AppLinks.appSettings),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                  ListenableBuilder(
                    listenable: settings,
                    builder: (context, _) => AppListGroup(
                      children: [
                        for (final (topic, title, hint) in topics)
                          AppListRow(
                            title: title,
                            subtitle: hint,
                            semanticLabel: title,
                            trailing: AppToggle(
                              value: settings.topicEnabled(topic),
                              semanticLabel: title,
                              onChanged: (on) => _toggle(topic, on),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                    ),
                    child: Text(
                      l10n.notifFooter,
                      style: text.caption.copyWith(color: c.textSecondary),
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
