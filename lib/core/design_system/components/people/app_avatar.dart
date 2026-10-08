import 'package:flutter/material.dart';

import '../../foundations/app_icons.dart';
import '../../foundations/context_extensions.dart';
import '../../tokens/app_radius.dart';

/// Avatar boyutları (DESIGN_SYSTEM.md §10 "Avatar").
enum AppAvatarSize {
  /// Metin içinde.
  xs(20),

  /// Avatar grupları.
  sm(28),

  /// Liste satırı, Participant Strip.
  md(40),

  /// Oda katılımcıları, bekleme ekranı, karar anı.
  lg(56),

  /// Profil.
  xl(88);

  const AppAvatarSize(this.dimension);

  final double dimension;
}

/// Her çalıştırmada ve her platformda aynı sonucu veren 32 bit FNV-1a hash'i.
///
/// Dart'ın `String.hashCode`'u sürümler arasında kararlılık garantisi vermez; tint seçimi
/// kullanıcı için kalıcı olmalı (aynı kişi hep aynı renk).
int stableHash(String value) {
  var hash = 0x811C9DC5;
  for (final unit in value.codeUnits) {
    hash ^= unit;
    // hash * 0x01000193 (mod 2^32), 53 bitlik tamsayı sınırını aşmadan.
    hash = (((hash << 24) & 0xFFFFFFFF) + hash * 0x193) & 0xFFFFFFFF;
  }
  return hash;
}

/// Baş harfler: tek sözcükte ilk harf, birden çok sözcükte ilk ve son sözcüğün ilk harfi
/// ([maxLetters] 1 ise yalnızca ilki). Büyük/küçük harf **dönüştürülmez** (Türkçe i/I hatası
/// olmasın diye); isim nasıl yazıldıysa öyle gösterilir.
String avatarInitials(String name, {int maxLetters = 2}) {
  final words = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((w) => w.isNotEmpty)
      .toList();
  if (words.isEmpty) return '';
  String first(String word) => String.fromCharCode(word.runes.first);
  if (words.length == 1 || maxLetters < 2) return first(words.first);
  return first(words.first) + first(words.last);
}

/// Avatar: insanlar daire, mekanlar `radius sm` kare (DESIGN_SYSTEM.md §10).
///
/// Fotoğrafsız insan avatarı baş harfler (600) ve `userId`'den deterministik seçilen 5 tintten
/// biridir. Online noktası yoktur. Yanında isim varsa süs olarak (semantics'siz) kalır; tek
/// başına anlam taşıyorsa [semanticLabel] verilir.
class AppAvatar extends StatelessWidget {
  const AppAvatar({
    super.key,
    required String this.userId,
    required this.name,
    this.image,
    this.size = AppAvatarSize.md,
    this.semanticLabel,
  }) : isPlace = false;

  /// Mekan avatarı: `radius sm` kare; fotoğrafsızsa harita ikonu.
  const AppAvatar.place({
    super.key,
    required this.name,
    this.image,
    this.size = AppAvatarSize.md,
    this.semanticLabel,
  }) : userId = null,
       isPlace = true;

  /// Tint seçimi için kalıcı kullanıcı kimliği (mekanda yok).
  final String? userId;

  /// Baş harfler için isim.
  final String name;

  /// Fotoğraf; yüklenemezse baş harflere düşer.
  final ImageProvider? image;
  final AppAvatarSize size;
  final bool isPlace;
  final String? semanticLabel;

  /// xs ve sm'de tek harf: küçük boyutlarda (özellikle üst üste binen grupta) iki harf sığmaz
  /// ya da komşu avatarın altında kalır.
  int get _maxLetters => size.index <= AppAvatarSize.sm.index ? 1 : 2;

  /// Fotoğrafsız avatar zemini: `userId`'den deterministik tint.
  static Color tintFor(BuildContext context, String userId) {
    final tints = context.colors.avatarTints;
    return tints[stableHash(userId) % tints.length];
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final dimension = size.dimension;

    final fallback = isPlace
        ? ColoredBox(
            color: c.surfaceMuted,
            child: Center(
              child: Icon(
                AppIcons.map,
                size: dimension * 0.5,
                color: c.textTertiary,
              ),
            ),
          )
        : ColoredBox(
            color: tintFor(context, userId!),
            child: Center(
              child: Text(
                avatarInitials(name, maxLetters: _maxLetters),
                // Avatar sabit boyutlu: Dynamic Type baş harfleri dışarı taşırmasın.
                textScaler: TextScaler.noScaling,
                maxLines: 1,
                style: context.text.label.copyWith(
                  fontSize: dimension * 0.4,
                  height: 1,
                  fontWeight: FontWeight.w600,
                  color: c.textPrimary,
                ),
              ),
            ),
          );

    final content = image == null
        ? fallback
        : Image(
            image: image!,
            fit: BoxFit.cover,
            width: dimension,
            height: dimension,
            errorBuilder: (context, error, stack) => fallback,
          );

    final avatar = SizedBox.square(
      dimension: dimension,
      child: ClipPath(
        clipper: ShapeBorderClipper(
          shape: isPlace
              ? AppRadius.border(AppRadius.sm)
              : const CircleBorder(),
        ),
        child: content,
      ),
    );

    if (semanticLabel == null) return ExcludeSemantics(child: avatar);
    return Semantics(
      label: semanticLabel,
      image: true,
      excludeSemantics: true,
      child: avatar,
    );
  }
}
