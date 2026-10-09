import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/app_links.dart';
import '../../app/app_router.dart';
import '../../app/app_scope.dart';
import '../../core/data/mock/mock_rooms_repository.dart';
import '../../core/design_system/components/buttons/app_button.dart';
import '../../core/design_system/components/buttons/app_icon_button.dart';
import '../../core/design_system/components/content/app_list_group.dart';
import '../../core/design_system/components/content/app_status_tag.dart';
import '../../core/design_system/components/feedback/app_alert.dart';
import '../../core/design_system/components/feedback/app_sheet.dart';
import '../../core/design_system/components/feedback/app_toast.dart';
import '../../core/design_system/components/inputs/app_text_field.dart';
import '../../core/design_system/components/people/app_avatar.dart';
import '../../core/design_system/components/people/participant_ring.dart';
import '../../core/design_system/foundations/app_haptics.dart';
import '../../core/design_system/foundations/app_icons.dart';
import '../../core/design_system/foundations/app_pressable.dart';
import '../../core/design_system/foundations/context_extensions.dart';
import '../../core/design_system/tokens/app_radius.dart';
import '../../core/design_system/tokens/app_spacing.dart';
import '../../core/domain/room.dart';
import '../../l10n/app_localizations.dart';

/// D2 · Oda (SCREENS D2 `RoomNew`): başlık, çerçeve etiketleri, katılımcılar, davet linki.
///
/// Katılımcı yokken Primary "Linki paylaş" + Tertiary "Önce ben seçeyim"; **ilk katılımcı
/// geldiği an** Primary "Seçmeye başla" olur ve davet alanı ikinci plana iner (link satırı
/// kalır). Oda ayarları "…" menüsündedir: ad değiştirme ve silme (alert).
class RoomScreen extends StatelessWidget {
  const RoomScreen({super.key, required this.roomId});

  final String roomId;

  @override
  Widget build(BuildContext context) {
    final rooms = AppScope.of(context).rooms;
    return ListenableBuilder(
      listenable: rooms,
      builder: (context, _) {
        final room = rooms.room(roomId);
        // Silinmiş oda: ekran zaten kapanıyor; bir kare boş kalır.
        if (room == null) {
          return Scaffold(backgroundColor: context.colors.canvas);
        }
        return _RoomView(room: room);
      },
    );
  }
}

enum _RoomAction { rename, delete }

/// Oda adı alanı; denetleyicisini kendisi yönetir.
class _RenameField extends StatefulWidget {
  const _RenameField({required this.initial, required this.onChanged});

  final String initial;
  final ValueChanged<String> onChanged;

  @override
  State<_RenameField> createState() => _RenameFieldState();
}

class _RenameFieldState extends State<_RenameField> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initial,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      label: AppLocalizations.of(context).createRoomName,
      controller: _controller,
      autofocus: true,
      textCapitalization: TextCapitalization.sentences,
      textInputAction: TextInputAction.done,
      onChanged: widget.onChanged,
    );
  }
}

class _RoomView extends StatelessWidget {
  const _RoomView({required this.room});

  final Room room;

  String get _link => AppLinks.invite(room.inviteSlug);

  Future<void> _share(BuildContext context) =>
      AppScope.of(context).sharer.share('https://$_link');

  Future<void> _copy(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    await Clipboard.setData(ClipboardData(text: _link));
    if (!context.mounted) return;
    AppHaptics.success();
    AppToast.show(context, message: l10n.roomLinkCopied);
  }

  /// Menüden seçilen eylem sheet tamamen kapandıktan sonra çalışır: aynı anda iki sheet
  /// açılamaz, kapanan sheet'in "açık" sayılması ad değiştirme sheet'ini engellerdi.
  Future<void> _settings(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final action = await AppSheet.show<_RoomAction>(
      context,
      title: l10n.roomSettings,
      builder: (sheetContext) => AppListGroup(
        children: [
          AppListRow(
            title: l10n.roomRename,
            onPressed: () => Navigator.of(sheetContext).pop(_RoomAction.rename),
          ),
          AppListRow(
            title: l10n.roomDelete,
            destructive: true,
            onPressed: () => Navigator.of(sheetContext).pop(_RoomAction.delete),
          ),
        ],
      ),
    );
    if (!context.mounted) return;
    switch (action) {
      case _RoomAction.rename:
        await _rename(context);
      case _RoomAction.delete:
        await _confirmDelete(context);
      case null:
        break;
    }
  }

  Future<void> _rename(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final rooms = AppScope.of(context).rooms;
    // Alanın kendi denetleyicisi sheet içinde yaşar (kapanış animasyonu sürerken
    // kullanılabilsin); dışarı yalnızca yazılan metin taşınır.
    final draft = ValueNotifier<String>(room.name);
    await AppSheet.show<void>(
      context,
      title: l10n.roomRename,
      builder: (_) =>
          _RenameField(initial: room.name, onChanged: (v) => draft.value = v),
      footer: Builder(
        builder: (sheetContext) => AppButton.primary(
          label: l10n.roomRenameSave,
          onPressed: () {
            final name = draft.value.trim();
            if (name.isEmpty) {
              AppHaptics.error();
              return;
            }
            Navigator.of(sheetContext).pop();
            rooms.rename(room.id, name);
          },
        ),
      ),
    );
    draft.dispose();
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final rooms = AppScope.of(context).rooms;
    final navigator = Navigator.of(context);
    final confirmed = await AppAlert.show(
      context,
      title: l10n.roomDeleteTitle,
      message: l10n.roomDeleteMessage,
      actionLabel: l10n.roomDeleteConfirm,
    );
    if (!confirmed) return;
    navigator.pop();
    await rooms.delete(room.id);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = context.colors;
    final text = context.text;
    final hasGuests = room.members.length > 1;

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
                  AppIconButton.plain(
                    icon: AppIcons.more,
                    semanticLabel: l10n.roomSettings,
                    onPressed: () => _settings(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screenPadding,
                  AppSpacing.xxs,
                  AppSpacing.screenPadding,
                  AppSpacing.xl,
                ),
                children: [
                  Semantics(
                    header: true,
                    child: Text(room.name, style: text.h1),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.xs - 2,
                    runSpacing: AppSpacing.xs - 2,
                    children: [
                      for (final tag in room.frameTags)
                        AppStatusTag.neutral(label: tag),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xxxl),
                  _Members(room: room),
                  const SizedBox(height: AppSpacing.md),
                  Semantics(
                    header: true,
                    child: Text(
                      hasGuests
                          ? l10n.roomMembersTitle(room.members.length)
                          : l10n.roomInviteTitle,
                      textAlign: TextAlign.center,
                      style: text.h3,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  _LinkRow(
                    link: _link,
                    onCopy: () => _copy(context),
                    quiet: hasGuests,
                  ),
                  if (kDebugMode) ...[
                    const SizedBox(height: AppSpacing.md),
                    Center(
                      child: AppButton.tertiary(
                        label: 'Arkadaş katıldı (debug)',
                        size: AppButtonSize.small,
                        fullWidth: false,
                        onPressed: () => _simulateJoin(context),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenPadding,
                AppSpacing.sm,
                AppSpacing.screenPadding,
                AppSpacing.xs,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: hasGuests
                    ? [
                        AppButton.primary(
                          label: l10n.roomStartPicking,
                          onPressed: () => AppRoutes.pushDeck(context, room.id),
                        ),
                        const SizedBox(height: AppSpacing.xxs),
                        AppButton.tertiary(
                          label: l10n.roomShare,
                          icon: AppIcons.share,
                          onPressed: () => _share(context),
                        ),
                      ]
                    : [
                        AppButton.primary(
                          label: l10n.roomShare,
                          icon: AppIcons.share,
                          onPressed: () => _share(context),
                        ),
                        const SizedBox(height: AppSpacing.xxs),
                        AppButton.tertiary(
                          label: l10n.roomPickFirst,
                          onPressed: () => AppRoutes.pushDeck(context, room.id),
                        ),
                      ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _simulateJoin(BuildContext context) {
    final rooms = AppScope.of(context).rooms;
    final repo = rooms.repository;
    if (repo is! MockRoomsRepository) return;
    repo.simulateJoin(room.id);
    rooms.load(silent: true);
  }
}

/// Katılımcılar: üyeler avatarla, kalan yerler kesik çizgili boş daireyle (en az dört yer).
class _Members extends StatelessWidget {
  const _Members({required this.room});

  final Room room;

  static const int _minSlots = 4;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final members = room.members;
    final empty = (_minSlots - members.length).clamp(0, _minSlots);
    return Semantics(
      label: members.length <= 1
          ? l10n.roomOnlyYouSemantics
          : l10n.roomMembersSemantics(members.length),
      excludeSemantics: true,
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: AppSpacing.xs,
        runSpacing: AppSpacing.xs,
        children: [
          for (final m in members)
            ParticipantRing(
              userId: m.id,
              name: m.name,
              status: ParticipantStatus.joined,
              size: AppAvatarSize.lg,
            ),
          for (var i = 0; i < empty; i++)
            const ParticipantRing(
              userId: '',
              name: '',
              status: ParticipantStatus.invited,
              size: AppAvatarSize.lg,
            ),
        ],
      ),
    );
  }
}

/// Davet linki satırı: link ikonu, kısaltılmış adres ve "Kopyala" pill'i. Katılımcı geldikten
/// sonra ikinci plana iner (`quiet`): gölgesiz, `surfaceMuted`.
class _LinkRow extends StatelessWidget {
  const _LinkRow({
    required this.link,
    required this.onCopy,
    required this.quiet,
  });

  final String link;
  final VoidCallback onCopy;
  final bool quiet;

  static const double _minHeight = 52;
  static const double _copyHeight = 40;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = context.colors;
    final e1 = context.elevation.e1;
    return DecoratedBox(
      decoration: AppRadius.decoration(
        radius: AppRadius.md,
        color: quiet ? c.surfaceMuted : c.surface,
        elevation: quiet ? null : e1,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: _minHeight),
        child: Padding(
          padding: const EdgeInsetsDirectional.only(
            start: AppSpacing.md,
            end: AppSpacing.xxs + 2,
          ),
          child: Row(
            children: [
              ExcludeSemantics(
                child: Icon(
                  AppIcons.link,
                  size: AppIconSize.s20,
                  color: c.textSecondary,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Semantics(
                  label: l10n.roomLinkSemantics(link),
                  excludeSemantics: true,
                  child: Text(
                    link,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.bodySmall.copyWith(
                      color: c.textSecondary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              AppPressable(
                onPressed: onCopy,
                semanticLabel: l10n.roomLinkCopy,
                builder: (context, _) => SizedBox(
                  height: AppSpacing.touchTarget,
                  child: Center(
                    child: DecoratedBox(
                      decoration: AppRadius.decoration(
                        radius: AppRadius.pill,
                        color: quiet ? c.surface : c.surfaceMuted,
                      ),
                      child: SizedBox(
                        height: _copyHeight,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm + 2,
                          ),
                          child: Center(
                            widthFactor: 1,
                            child: Text(
                              l10n.roomLinkCopy,
                              style: context.text.label.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
