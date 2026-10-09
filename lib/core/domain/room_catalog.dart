import 'package:flutter/foundation.dart';

/// Odanın kategori türü: mekan (konum, mesafe, bütçe) ya da film/dizi (platform).
enum RoomKind { place, film }

/// Oda kategorisi. Liste sunucudan gelir (SCREENS D1); arayüz sayıya bağımlı olmamalı.
@immutable
class RoomCategory {
  const RoomCategory({
    required this.id,
    required this.label,
    required this.inlineLabel,
    this.kind = RoomKind.place,
  });

  final String id;

  /// Başlık biçimi ("Yemek").
  final String label;

  /// Cümle içi biçimi ("yemek"): "Bu akşam yemek" gibi oda adlarında kullanılır. Küçük harfe
  /// çevirme kodda yapılmaz (Türkçe i/ı hatası); veri katmanı doğru biçimi verir.
  final String inlineLabel;
  final RoomKind kind;
}

/// "Bugüne özel" tema kartı (bağlama duyarlı; veri gelene kadar sabit liste).
@immutable
class RoomTheme {
  const RoomTheme({
    required this.id,
    required this.label,
    required this.categoryId,
    required this.when,
    this.tintIndex = 0,
  });

  final String id;
  final String label;

  /// Temanın açtığı kategori.
  final String categoryId;
  final RoomWhen when;
  final int tintIndex;
}

/// "Ne zaman" seçenekleri.
enum RoomWhen { now, tonight, weekend, date }

/// Oda kurma ekranlarının ihtiyaç duyduğu seçenek verileri.
@immutable
class RoomCatalog {
  const RoomCatalog({
    required this.categories,
    required this.themes,
    required this.platforms,
    required this.districts,
  });

  final List<RoomCategory> categories;
  final List<RoomTheme> themes;
  final List<String> platforms;
  final List<String> districts;

  RoomCategory? category(String id) {
    for (final c in categories) {
      if (c.id == id) return c;
    }
    return null;
  }
}

/// Oda kurma formunun sonucu. Etiketler (`whenLabel`, `frameTags`) formu dolduran arayüzde,
/// kullanıcının dilinde biçimlenmiş gelir; gerçek veri katmanı yapılandırılmış alanları da
/// (kategori, zaman, bütçe, konum) kullanacak.
@immutable
class RoomDraft {
  const RoomDraft({
    required this.name,
    required this.category,
    required this.whenLabel,
    required this.frameTags,
  });

  final String name;
  final RoomCategory category;
  final String whenLabel;
  final List<String> frameTags;
}
