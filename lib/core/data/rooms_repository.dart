import '../domain/room.dart';

/// Oda verisinin kaynağı. Şimdilik sahte ([MockRoomsRepository]); gerçek veri katmanı aynı
/// arayüzü uygular.
abstract interface class RoomsRepository {
  /// Kullanıcının odaları, sıralama yapılmadan.
  Future<List<Room>> rooms();

  /// Geçmiş kararlar, yeniden eskiye.
  Future<List<PastDecision>> history();
}
