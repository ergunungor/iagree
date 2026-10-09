import 'package:flutter/material.dart';

import '../../app/app_router.dart';
import '../../app/app_scope.dart';
import '../../app/rooms_controller.dart';
import '../../core/design_system/components/buttons/app_button.dart';
import '../../core/design_system/components/buttons/app_icon_button.dart';
import '../../core/design_system/components/content/app_card.dart';
import '../../core/design_system/components/content/app_list_group.dart';
import '../../core/design_system/components/content/app_status_tag.dart';
import '../../core/design_system/components/feedback/app_empty_state.dart';
import '../../core/design_system/components/feedback/app_skeleton.dart';
import '../../core/design_system/components/feedback/app_toast.dart';
import '../../core/design_system/components/people/app_avatar.dart';
import '../../core/design_system/foundations/app_icons.dart';
import '../../core/design_system/foundations/app_pressable.dart';
import '../../core/design_system/foundations/context_extensions.dart';
import '../../core/design_system/tokens/app_radius.dart';
import '../../core/design_system/tokens/app_spacing.dart';
import '../../core/design_system/tokens/app_typography.dart';
import '../../core/domain/room.dart';
import '../../l10n/app_localizations.dart';

/// C1 · Odalarım (SCREENS C1): hero kart (en acil oda) → diğer odalar → geçmiş kararlar.
/// Hiç oda yoksa `HomeEmpty`: boş durum + altta tek Primary "Oda oluştur".
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    final rooms = AppScope.of(context).rooms;
    if (rooms.status == RoomsStatus.idle) rooms.load();
  }

  void _soon() =>
      AppToast.show(context, message: AppLocalizations.of(context).comingSoon);

  /// Davet aşamasındaki oda (D2) açılır; diğer aşamalar (deste, bekleme, sonuçlar) sonraki
  /// ekranlarla bağlanacak.
  void _openRoom(Room room) {
    if (room.isInviting && room.members.isNotEmpty) {
      AppRoutes.pushRoom(context, room);
    } else {
      _soon();
    }
  }

  @override
  Widget build(BuildContext context) {
    final rooms = AppScope.of(context).rooms;
    final c = context.colors;
    return Scaffold(
      backgroundColor: c.canvas,
      body: SafeArea(
        child: ListenableBuilder(
          listenable: rooms,
          builder: (context, _) {
            return switch (rooms.status) {
              RoomsStatus.idle || RoomsStatus.loading => const _Loading(),
              RoomsStatus.failed => _Failed(onRetry: rooms.load),
              RoomsStatus.ready when rooms.rooms.isEmpty => _Empty(
                onCreate: () => AppRoutes.pushCreateWhat(context),
              ),
              RoomsStatus.ready => _Loaded(
                rooms: rooms,
                onCreate: () => AppRoutes.pushCreateWhat(context),
                onOpenRoom: _openRoom,
                onOpenDecision: (_) => _soon(),
              ),
            };
          },
        ),
      ),
    );
  }
}

/// Sağ üst: "+" ve profil avatarı. Üst bölgede başlık [title] ile birlikte kayar.
class _Header extends StatelessWidget {
  const _Header({this.onCreate});

  final VoidCallback? onCreate;

  /// Avatar 28pt, dokunma alanı 44pt.
  static const double _edgeBleed = AppSpacing.xs;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final user = AppScope.of(context).session.user;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Transform.translate(
          offset: const Offset(_edgeBleed, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (onCreate != null)
                AppIconButton.plain(
                  icon: AppIcons.plus,
                  semanticLabel: l10n.homeCreateRoom,
                  onPressed: onCreate,
                ),
              AppPressable(
                onPressed: () => AppRoutes.pushAccount(context),
                semanticLabel: l10n.homeProfile,
                minWidth: AppSpacing.touchTarget,
                builder: (context, _) => SizedBox.square(
                  dimension: AppSpacing.touchTarget,
                  child: Center(
                    child: AppAvatar(
                      userId: user?.id ?? '',
                      name: user?.name ?? '',
                      size: AppAvatarSize.sm,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xxs),
        Semantics(
          header: true,
          child: Text(l10n.homeTitle, style: context.text.h1),
        ),
      ],
    );
  }
}

class _Loaded extends StatelessWidget {
  const _Loaded({
    required this.rooms,
    required this.onCreate,
    required this.onOpenRoom,
    required this.onOpenDecision,
  });

  final RoomsController rooms;
  final VoidCallback onCreate;
  final ValueChanged<Room> onOpenRoom;
  final ValueChanged<PastDecision> onOpenDecision;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final hero = rooms.hero!;
    final others = rooms.others;
    final history = rooms.history;
    return ListView(
      padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
      children: [
        _Padded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Header(onCreate: onCreate),
              const SizedBox(height: AppSpacing.lg),
              _HeroCard(room: hero, onPressed: () => onOpenRoom(hero)),
              if (others.isNotEmpty) ...[
                _SectionTitle(l10n.homeOtherRooms),
                AppListGroup(
                  children: [
                    for (final room in others)
                      _roomRow(context, room, () => onOpenRoom(room)),
                  ],
                ),
              ],
              if (history.isNotEmpty) _SectionTitle(l10n.homePastDecisions),
            ],
          ),
        ),
        // Karo şeridi kenardan kenara kayar; ilk karo ekran kenar boşluğundan başlar.
        if (history.isNotEmpty)
          _History(items: history, onPressed: onOpenDecision),
      ],
    );
  }
}

/// Ekran kenar boşluğu.
class _Padded extends StatelessWidget {
  const _Padded({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
    child: child,
  );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        top: AppSpacing.xl + AppSpacing.xxs,
        bottom: AppSpacing.sm,
      ),
      child: Semantics(
        header: true,
        child: Text(text, style: context.text.title),
      ),
    );
  }
}

/// Aksiyon bekleyen en acil oda. Aksiyon ekranın tek Primary'sidir; yalnızca başkaları
/// bekleniyorsa (kullanıcının yapacağı bir şey yok) Secondary.
class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.room, required this.onPressed});

  final Room room;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = context.colors;
    final text = context.text;

    final (label, body, action) = switch (room.stage) {
      RoomStage.resultsReady => (
        l10n.homeHeroResultsLabel,
        l10n.homeHeroResultsBody(room.previews.length),
        l10n.homeHeroVote,
      ),
      RoomStage.yourTurn => (
        l10n.homeHeroTurnLabel,
        l10n.homeHeroTurnBody(room.readyCount, room.participantCount),
        l10n.homeHeroPick,
      ),
      RoomStage.waiting => (
        l10n.homeHeroWaitLabel,
        l10n.homeHeroWaitBody(room.readyCount, room.participantCount),
        l10n.homeHeroOpen,
      ),
    };

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            container: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: text.caption.copyWith(
                    color: c.brand,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(room.name, style: text.h2),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  l10n.homeHeroMeta(
                    room.categoryLabel,
                    room.whenLabel,
                    room.participantCount,
                  ),
                  style: text.caption.copyWith(color: c.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(body, style: text.bodySmall.copyWith(color: c.textSecondary)),
          if (room.previews.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            _Previews(previews: room.previews),
          ],
          const SizedBox(height: AppSpacing.md),
          room.stage == RoomStage.waiting
              ? AppButton.secondary(label: action, onPressed: onPressed)
              : AppButton.primary(label: action, onPressed: onPressed),
        ],
      ),
    );
  }
}

/// Önizleme karoları: eşit genişlikte üç sütun; mekan adı tek satır, altında uyum yüzdesi.
class _Previews extends StatelessWidget {
  const _Previews({required this.previews});

  final List<PlacePreview> previews;

  static const double _photoHeight = 64;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = context.colors;
    final text = context.text;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < previews.length; i++) ...[
          if (i > 0) const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Semantics(
              label: l10n.homePreviewSemantics(
                previews[i].name,
                previews[i].agreementPercent,
              ),
              excludeSemantics: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipPath(
                    clipper: ShapeBorderClipper(
                      shape: AppRadius.border(AppRadius.sm),
                    ),
                    child: SizedBox(
                      height: _photoHeight,
                      width: double.infinity,
                      child: ColoredBox(
                        color:
                            c.avatarTints[previews[i].tintIndex %
                                c.avatarTints.length],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxs + 2),
                  Text(
                    previews[i].name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.caption.copyWith(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    l10n.homeAgreement(previews[i].agreementPercent),
                    style: text.caption.tabular.copyWith(
                      color: c.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Diğer odalar listesindeki satır. Durum görsel öğeyle (etiket ya da sayaç) anlatılır,
/// VoiceOver etiketi aynı bilgiyi cümle olarak taşır.
AppListRow _roomRow(BuildContext context, Room room, VoidCallback onPressed) {
  final l10n = AppLocalizations.of(context);
  final c = context.colors;
  final meta = l10n.homeRoomMeta(room.categoryLabel, room.whenLabel);

  final (status, trailing) = switch (room.stage) {
    RoomStage.resultsReady => (
      l10n.homeTagResults,
      AppStatusTag(label: l10n.homeTagResults),
    ),
    RoomStage.yourTurn => (
      l10n.homeTagYourTurn,
      AppStatusTag(label: l10n.homeTagYourTurn),
    ),
    RoomStage.waiting => (
      l10n.homeReadyCount(room.readyCount, room.participantCount),
      ExcludeSemantics(
        child: Text(
          l10n.homeReadyCount(room.readyCount, room.participantCount),
          style: context.text.caption.tabular.copyWith(color: c.textSecondary),
        ),
      ),
    ),
  };

  return AppListRow(
    title: room.name,
    subtitle: meta,
    emphasized: true,
    verticalPadding: AppSpacing.sm - 2,
    trailing: trailing,
    semanticLabel: l10n.homeRoomSemantics(room.name, meta, status),
    onPressed: onPressed,
  );
}

/// Yatay kaydırılan karo şeridi; sağ kenara taşar (kaydırılabilirlik ipucu).
class _History extends StatelessWidget {
  const _History({required this.items, required this.onPressed});

  final List<PastDecision> items;
  final ValueChanged<PastDecision> onPressed;

  static const double _tileWidth = 148;
  static const double _photoHeight = 96;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = context.text;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) const SizedBox(width: AppSpacing.sm),
            AppPressable(
              onPressed: () => onPressed(items[i]),
              semanticLabel: '${items[i].title}, ${items[i].dateLabel}',
              minWidth: _tileWidth,
              builder: (context, _) => SizedBox(
                width: _tileWidth,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipPath(
                      clipper: ShapeBorderClipper(
                        shape: AppRadius.border(AppRadius.md),
                      ),
                      child: SizedBox(
                        height: _photoHeight,
                        width: double.infinity,
                        child: ColoredBox(
                          color:
                              c.avatarTints[items[i].tintIndex %
                                  c.avatarTints.length],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxs + 2),
                    Text(
                      items[i].title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.bodySmall.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      items[i].dateLabel,
                      style: text.caption.copyWith(color: c.textSecondary),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// İlk kullanım: boş durum + altta tek Primary.
class _Empty extends StatelessWidget {
  const _Empty({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
          child: _Header(),
        ),
        Expanded(
          child: Align(
            alignment: const Alignment(0, -0.35),
            child: SingleChildScrollView(
              child: AppEmptyState.dashedAvatars(
                title: l10n.homeEmptyTitle,
                message: l10n.homeEmptyBody,
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenPadding,
            AppSpacing.sm,
            AppSpacing.screenPadding,
            AppSpacing.md,
          ),
          child: AppButton.primary(
            label: l10n.homeCreateRoom,
            icon: AppIcons.plus,
            onPressed: onCreate,
          ),
        ),
      ],
    );
  }
}

class _Failed extends StatelessWidget {
  const _Failed({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
          child: _Header(),
        ),
        Expanded(
          child: Align(
            alignment: const Alignment(0, -0.35),
            child: SingleChildScrollView(
              child: AppEmptyState.error(
                title: l10n.homeLoadFailedTitle,
                message: l10n.homeLoadFailedBody,
                actionLabel: l10n.homeRetry,
                onAction: onRetry,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading();

  static const double _heroHeight = 264;
  static const double _rowHeight = 60;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _Header(),
          const SizedBox(height: AppSpacing.lg),
          const AppSkeleton(height: _heroHeight, radius: AppRadius.lg),
          const SizedBox(height: AppSpacing.xl),
          const AppSkeleton(height: _rowHeight, radius: AppRadius.lg),
          const SizedBox(height: AppSpacing.sm),
          const AppSkeleton(height: _rowHeight, radius: AppRadius.lg),
        ],
      ),
    );
  }
}
