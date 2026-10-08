import 'dart:math' as math;

/// AgreementArc'ın saf hesapları (DESIGN_SYSTEM.md §10 "AgreementArc"). Çizimden bağımsızdır,
/// birim testle doğrulanır.
abstract final class AgreementMath {
  /// Yüzde = (Olur + Çok isterim) / toplam kişi. Ağırlıklı skor yok.
  ///
  /// **Aşağı yuvarlanır:** `%100` yalnızca gerçekten herkes olumluysa çıkar (199/200 → 99,
  /// 2/3 → 66). Hiç kişi yoksa 0.
  static int percent({
    required int loveCount,
    required int okCount,
    required int total,
  }) {
    assert(
      loveCount >= 0 && okCount >= 0 && total >= 0,
      'Sayılar negatif olamaz.',
    );
    assert(loveCount + okCount <= total, 'Olumlu sayısı toplamı aşamaz.');
    if (total <= 0) return 0;
    final positive = loveCount + okCount;
    return math.min(positive, total) * 100 ~/ total;
  }
}

/// Yayın hangi payın rengiyle çizildiği.
enum ArcTone { love, ok }

/// Yarım dairenin merkez çizgisi üzerinde bir dilim; `start` ve `end` 0–1 arası, 0 soldaki uç.
class ArcSegment {
  const ArcSegment(this.start, this.end, this.tone);

  final double start;
  final double end;
  final ArcTone tone;

  @override
  bool operator ==(Object other) =>
      other is ArcSegment &&
      other.start == start &&
      other.end == end &&
      other.tone == tone;

  @override
  int get hashCode => Object.hash(start, end, tone);

  @override
  String toString() => 'ArcSegment($start, $end, $tone)';
}

/// Yay dilimlerini üretir: soldan sağa Çok isterim, boşluk, Olur.
///
/// Uçlar yuvarlak çizildiği için her dilim çizgi kalınlığının yarısı kadar iki yana taşar.
/// Görsel boşluk [gap] olsun diye iki dilim sınırdan `(gap + strokeWidth) / 2` geri çekilir.
/// Çok küçük bir dilimde bu çekilme dilimi bir noktaya (uzunluk 0) indirir, eksiye düşürmez.
/// [singleTone] (karar anı) tek tondur: boşluk yok, tek dilim.
List<ArcSegment> arcSegments({
  required int loveCount,
  required int okCount,
  required int total,
  required double radius,
  required double strokeWidth,
  double gap = 2,
  bool singleTone = false,
}) {
  if (total <= 0 || loveCount + okCount <= 0) return const [];
  final loveFraction = loveCount / total;
  final okFraction = okCount / total;

  if (singleTone) {
    return [ArcSegment(0, loveFraction + okFraction, ArcTone.love)];
  }
  if (okCount == 0) return [ArcSegment(0, loveFraction, ArcTone.love)];
  if (loveCount == 0) return [ArcSegment(0, okFraction, ArcTone.ok)];

  final shrink = ((gap + strokeWidth) / 2) / (radius * math.pi);
  final boundary = loveFraction;
  final okEnd = loveFraction + okFraction;
  return [
    ArcSegment(0, math.max(0, boundary - shrink), ArcTone.love),
    ArcSegment(math.min(boundary + shrink, okEnd), okEnd, ArcTone.ok),
  ];
}
