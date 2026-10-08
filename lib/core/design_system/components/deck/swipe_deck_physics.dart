import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/foundation.dart';

/// Kart destesinin dört kararı. Yön: → Olur, ← Pas, ↑ Çok isterim, ↓ Olmaz.
enum DeckDecision { ok, pass, love, veto }

/// Kartın o anki görsel durumu: ofset, dönme ve yön/ilerleme (etiket ve ton için).
@immutable
class SwipeFrame {
  const SwipeFrame({
    required this.offset,
    this.rotation = 0,
    this.direction,
    this.progress = 0,
  });

  static const SwipeFrame rest = SwipeFrame(offset: Offset.zero);

  /// Kartın ana konumuna göre kayması.
  final Offset offset;

  /// Radyan; pivot kartın alt ortası.
  final double rotation;

  /// Kartın şu an yöneldiği karar; hareket yoksa null.
  final DeckDecision? direction;

  /// Eşiğe göre ilerleme: 0 → başlangıç, 1 → eşik, 1'den büyük → eşiği aştı.
  final double progress;

  bool get armed => progress >= 1;

  /// Etiket opaklığı: eşiğe kadar 0→1.
  double get labelOpacity => progress.clamp(0.0, 1.0);

  /// Kart renk tonu: eşikte en fazla `tintMaxAlpha`.
  double get tintAlpha => SwipePhysics.tintMaxAlpha * labelOpacity;

  /// Ekran zemin tonu: eşikte en fazla `screenTintMaxAlpha`.
  double get screenTintAlpha => SwipePhysics.screenTintMaxAlpha * labelOpacity;

  @override
  bool operator ==(Object other) =>
      other is SwipeFrame &&
      other.offset == offset &&
      other.rotation == rotation &&
      other.direction == direction &&
      other.progress == progress;

  @override
  int get hashCode => Object.hash(offset, rotation, direction, progress);
}

/// Deste fiziği (DESIGN_SYSTEM.md §10 "SwipeDeck" tablosu ve "Fizik" maddesi). Saf hesap;
/// widget'a bağlı değildir ve birim testle doğrulanır.
abstract final class SwipePhysics {
  /// Kart bu kadar (pt) hareket etmeden yön/etiket belirmez; hız tek başına da karar saymaz.
  static const double minDirectionDistance = 12;

  /// Yatayda kart dönme sınırı (derece).
  static const double maxRotationDegrees = 12;

  /// Aşağı yönde kartın parmağa oranı.
  static const double downResistance = 0.55;

  /// Baskın eksenin dışına izin verilen en fazla hareket (pt). Yumuşak sınır: ilk hareket
  /// 1:1, sınıra yaklaştıkça yavaşlar.
  static const double crossAxisAllowance = 24;

  /// Bu hızı (pt/s) aşan fırlatma, mesafe yetmese de karar sayılır (↓ hariç).
  static const double flingVelocity = 800;

  /// Uçuşun en düşük hızı (pt/s).
  static const double minFlyVelocity = 1000;

  static const double horizontalThreshold = 0.30;
  static const double upThreshold = 0.25;
  static const double downThreshold = 0.35;

  /// Renk tonunun eşikteki en yüksek opaklığı.
  static const double tintMaxAlpha = 0.20;

  /// Sürükleme sırasında ekran zemininin eşikteki en yüksek ton opaklığı (kart tonundan biraz yukarıda: zemin geniş bir alan, renk ayırt edilmeli).
  static const double screenTintMaxAlpha = 0.25;

  /// Ekranın alt kenarında bu kadar pt'lik şeritte başlayan dokunuş deste hareketi sayılmaz.
  static const double bottomGuard = 20;

  /// Karar eşiği (pt): yatayda kart genişliği, dikeyde kart yüksekliği üzerinden.
  static double thresholdOf(DeckDecision decision, Size card) =>
      switch (decision) {
        DeckDecision.ok ||
        DeckDecision.pass => card.width * horizontalThreshold,
        DeckDecision.love => card.height * upThreshold,
        DeckDecision.veto => card.height * downThreshold,
      };

  /// Çapraz eksen hareketi: ilk ufak harekette 1:1, [crossAxisAllowance]'a doğru doygun.
  static double softCross(double delta) {
    const l = crossAxisAllowance;
    final x = (delta / l).clamp(-20.0, 20.0);
    final e = math.exp(2 * x);
    return (l * (e - 1) / (e + 1)).clamp(-l, l);
  }

  /// Parmağın başlangıçtan toplam hareketi → kart ofseti.
  ///
  /// Eksen **kilitli değildir**: baskın eksen her harekette parmağın konumundan yeniden
  /// bulunur, böylece parmağı kaldırmadan yatayda başlayıp dikeye (ya da tersine) geçilebilir.
  /// Baskın eksen 1:1 (aşağı 0,55), diğer eksen yumuşak sınırlı. İki eksen arasındaki geçiş
  /// bir bantta sürekli harmanlanır ([_dominance]); kart hiçbir zaman sıçramaz.
  static Offset cardOffset(Offset finger) {
    final s = _dominance(finger);
    final crossX = (1 - s) / 2; // x ne kadar "çapraz" sayılıyor
    final crossY = (1 + s) / 2;
    final yMain = finger.dy > 0 ? finger.dy * downResistance : finger.dy;
    final x = finger.dx + (softCross(finger.dx) - finger.dx) * crossX;
    final y = yMain + (softCross(finger.dy) - yMain) * crossY;
    return Offset(x, y);
  }

  /// Baskın eksen ölçüsü: +1 yatay baskın, −1 dikey baskın, 0 köşegen. Geçiş bandı hareket
  /// büyüdükçe genişler (en az [crossAxisAllowance], en çok hareketin %60'ı): uzak
  /// konumlarda eksen değişirken kart aşırı hızlı yer değiştirmez.
  static double _dominance(Offset o) {
    final a = o.dx.abs();
    final b = o.dy.abs();
    final band = math.max(crossAxisAllowance, 0.6 * math.max(a, b));
    return ((a - b) / band).clamp(-1.0, 1.0);
  }

  /// Kart ofsetinden görsel durum. Yön, eşiğe göre daha ilerlemiş eksenin yönüdür; dönme
  /// yatay baskınlıkla orantılı olarak devreye girer (dikeyde dönme yok).
  static SwipeFrame frame(Offset offset, Size card) {
    if (offset.distance < minDirectionDistance) {
      return SwipeFrame(offset: offset, rotation: _rotation(offset, card));
    }
    final h = offset.dx > 0 ? DeckDecision.ok : DeckDecision.pass;
    final v = offset.dy < 0 ? DeckDecision.love : DeckDecision.veto;
    final ph = offset.dx.abs() / thresholdOf(h, card);
    final pv = offset.dy.abs() / thresholdOf(v, card);
    final horizontal = ph >= pv;
    return SwipeFrame(
      offset: offset,
      rotation: _rotation(offset, card),
      direction: horizontal ? h : v,
      progress: horizontal ? ph : pv,
    );
  }

  static double _rotation(Offset offset, Size card) {
    final maxRad = maxRotationDegrees * math.pi / 180;
    final horizontalWeight = (1 + _dominance(offset)) / 2;
    return (offset.dx / card.width * maxRad).clamp(-maxRad, maxRad) *
        horizontalWeight;
  }

  /// Bırakınca karar: mesafe veya (↓ hariç) hız. Önce daha ilerlemiş eksen, olmazsa diğer
  /// eksen denenir. Hız, kartın gittiği yönle aynı olmalı ve kart en az
  /// [minDirectionDistance] oynamış olmalı; aksi hâlde karar yok, kart geri döner.
  /// [velocity] parmağın pt/s hızıdır.
  static DeckDecision? decide({
    required Offset offset,
    required Offset velocity,
    required Size card,
  }) {
    final primary = frame(offset, card).direction;
    final h = offset.dx > 0 ? DeckDecision.ok : DeckDecision.pass;
    final v = offset.dy < 0 ? DeckDecision.love : DeckDecision.veto;
    final horizontal =
        primary == DeckDecision.ok || primary == DeckDecision.pass;
    final order = primary == null
        ? [h, v]
        : horizontal
        ? [primary, v]
        : [primary, h];
    for (final d in order) {
      if (_qualifies(d, offset, velocity, card)) return d;
    }
    return null;
  }

  static bool _qualifies(
    DeckDecision d,
    Offset offset,
    Offset velocity,
    Size card,
  ) {
    final threshold = thresholdOf(d, card);
    switch (d) {
      case DeckDecision.ok:
        return offset.dx > 0 &&
            (offset.dx >= threshold ||
                (offset.dx >= minDirectionDistance &&
                    velocity.dx > flingVelocity));
      case DeckDecision.pass:
        return offset.dx < 0 &&
            (-offset.dx >= threshold ||
                (-offset.dx >= minDirectionDistance &&
                    -velocity.dx > flingVelocity));
      case DeckDecision.love:
        return offset.dy < 0 &&
            (-offset.dy >= threshold ||
                (-offset.dy >= minDirectionDistance &&
                    -velocity.dy > flingVelocity));
      case DeckDecision.veto:
        // Olmaz yalnızca mesafeyle; hız tek başına sayılmaz.
        return offset.dy > 0 && offset.dy >= threshold;
    }
  }

  /// Uçuşun bitiş ofseti: karar yönünde ekran dışı, çapraz eksen olduğu gibi.
  static Offset flyTarget(DeckDecision decision, Offset from, Size screen) =>
      switch (decision) {
        DeckDecision.ok => Offset(screen.width, from.dy),
        DeckDecision.pass => Offset(-screen.width, from.dy),
        DeckDecision.love => Offset(from.dx, -screen.height),
        DeckDecision.veto => Offset(from.dx, screen.height),
      };

  /// Uçuş süresi: `mesafe / max(hız, 1000)`; [min] ile [max] arasına kıstırılır.
  static Duration flyDuration({
    required double distance,
    required double speed,
    required Duration min,
    required Duration max,
  }) {
    final v = math.max(speed.abs(), minFlyVelocity);
    final d = Duration(microseconds: (distance.abs() / v * 1e6).round());
    if (d < min) return min;
    if (d > max) return max;
    return d;
  }
}
