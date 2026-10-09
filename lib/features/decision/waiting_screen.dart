import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../app/app_router.dart';
import '../../app/app_scope.dart';
import '../../app/rooms_controller.dart';
import '../../core/data/mock/mock_rooms_repository.dart';
import '../../core/design_system/components/buttons/app_button.dart';
import '../../core/design_system/components/people/app_avatar.dart';
import '../../core/design_system/components/people/participant_ring.dart';
import '../../core/design_system/foundations/context_extensions.dart';
import '../../core/design_system/tokens/app_spacing.dart';
import '../../core/domain/room.dart';
import '../../l10n/app_localizations.dart';

/// D6 · Bekleme (SCREENS D6): "Sen hazırsın" + kaç kişinin hâlâ seçtiği; katılımcı halkaları
/// canlı dolar. Primary yok; "Odaya dön" Tertiary. Herkes bitince oybirliği varsa karar anına,
/// yoksa sonuçlara geçilir.
///
/// Bildirim izni kartı bu ekranın parçasıdır ama bildirim paketi (yerel/uzak) henüz
/// seçilmedi; kart o zaman eklenecek.
class WaitingScreen extends StatefulWidget {
  const WaitingScreen({super.key, required this.roomId});

  final String roomId;

  @override
  State<WaitingScreen> createState() => _WaitingScreenState();
}

class _WaitingScreenState extends State<WaitingScreen> {
  late final RoomsController _rooms;
  bool _started = false;
  bool _left = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _rooms = AppScope.of(context).rooms..addListener(_onChange);
  }

  @override
  void dispose() {
    _rooms.removeListener(_onChange);
    super.dispose();
  }

  /// Oda durumu değişince uygun ekrana geçilir (tek sefer).
  void _onChange() {
    if (_left || !mounted) return;
    final room = AppScope.of(context).rooms.room(widget.roomId);
    if (room == null) return;
    switch (room.stage) {
      case RoomStage.resultsReady:
        _left = true;
        AppRoutes.replaceWithResults(context, room.id);
      case RoomStage.decided:
        _left = true;
        AppRoutes.replaceWithDecision(context, room.id, animate: true);
      case RoomStage.yourTurn || RoomStage.waiting:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = context.colors;
    final rooms = AppScope.of(context).rooms;
    return Scaffold(
      backgroundColor: c.canvas,
      body: SafeArea(
        child: ListenableBuilder(
          listenable: rooms,
          builder: (context, _) {
            final room = rooms.room(widget.roomId);
            if (room == null) return const SizedBox.shrink();
            final members = room.members;
            final ready = room.readyCount.clamp(0, members.length);
            return Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenPadding,
              ),
              child: Column(
                children: [
                  Expanded(
                    child: Center(
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Wrap(
                              alignment: WrapAlignment.center,
                              spacing: AppSpacing.xs,
                              runSpacing: AppSpacing.xs,
                              children: [
                                for (var i = 0; i < members.length; i++)
                                  ParticipantRing(
                                    userId: members[i].id,
                                    name: members[i].name,
                                    status: i < ready
                                        ? ParticipantStatus.ready
                                        : ParticipantStatus.choosing,
                                    progress: 0.4,
                                    size: AppAvatarSize.lg,
                                  ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.xl),
                            Semantics(
                              header: true,
                              liveRegion: true,
                              child: Text(
                                l10n.waitingReady,
                                textAlign: TextAlign.center,
                                style: context.text.h1,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              l10n.waitingOthers(members.length - ready),
                              textAlign: TextAlign.center,
                              style: context.text.body.copyWith(
                                color: c.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (kDebugMode) _DebugControls(roomId: room.id),
                  AppButton.tertiary(
                    label: l10n.waitingBack,
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Debug: diğer kişilerin bitirmesini taklit eder.
class _DebugControls extends StatelessWidget {
  const _DebugControls({required this.roomId});

  final String roomId;

  @override
  Widget build(BuildContext context) {
    final rooms = AppScope.of(context).rooms;
    final repo = rooms.repository;
    if (repo is! MockRoomsRepository) return const SizedBox.shrink();
    Widget button(String label, bool unanimous) => AppButton.tertiary(
      label: label,
      size: AppButtonSize.small,
      fullWidth: false,
      onPressed: () {
        repo.simulateEveryoneDone(roomId, unanimous: unanimous);
        rooms.refresh();
      },
    );
    return Wrap(
      alignment: WrapAlignment.center,
      children: [
        button('Herkes bitirdi: oybirliği (debug)', true),
        button('Herkes bitirdi: oylama (debug)', false),
      ],
    );
  }
}
