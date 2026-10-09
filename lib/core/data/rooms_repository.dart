import '../domain/candidate.dart';
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

  /// Odanın destesi (kartlar).
  Future<List<Candidate>> deck(String roomId);

  /// Kullanıcının deste kararlarını gönderir; oda "başkaları bekleniyor"a geçer.
  Future<Room> submitPicks(String roomId, Map<String, Pick> picks);

  /// Oy aşaması: en uyumlu seçenekler ve (oy verildiyse) oylar.
  Future<RoomResults> results(String roomId);

  /// Kullanıcının oyunu verir.
  Future<Room> vote(String roomId, String candidateId);

  /// Eşitlikte oda sahibinin son sözü: seçilen seçenek karar olur.
  Future<Room> breakTie(String roomId, String candidateId);
}
