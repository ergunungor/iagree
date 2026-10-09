import '../domain/room.dart';
import '../domain/room_catalog.dart';

/// Oda verisinin kaynağı. Şimdilik sahte ([MockRoomsRepository]); gerçek veri katmanı aynı
/// arayüzü uygular.
abstract interface class RoomsRepository {
  /// Kullanıcının odaları, sıralama yapılmadan.
  Future<List<Room>> rooms();

  /// Geçmiş kararlar, yeniden eskiye.
  Future<List<PastDecision>> history();

  /// Oda kurma ekranlarının seçenekleri (kategoriler, temalar, platformlar, semtler).
  Future<RoomCatalog> catalog();

  /// Oda kurar; [owner] odanın ilk üyesidir. Yeni oda davet durumundadır.
  Future<Room> createRoom(RoomDraft draft, {required RoomMember owner});

  Future<Room> renameRoom(String id, String name);

  Future<void> deleteRoom(String id);
}
