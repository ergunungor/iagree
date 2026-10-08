import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/foundation.dart';

/// Kart destesinin dört kararı. Yön: → Olur, ← Pas, ↑ Çok isterim, ↓ Olmaz.
enum DeckDecision { ok, pass, love, veto }

/// Sürüklemenin kilitlendiği eksen.
enum DeckAxis { horizontal, vertical }

/// Kartın o anki görsel durumu: ofset, dönme ve yön/ilerleme (etiket ve ton için).
@immutable
class SwipeFrame {
  const SwipeFrame({
    required this.offset,
    this.rotation = 0,
    this.axis,
    this.direction,
    this.progress = 0,
  });

  static const SwipeFrame rest = SwipeFrame(offset: Offset.zero);

  /// Kartın ana konumuna göre kayması.
  final Offset offset;

  /// Radyan; pivot kartın alt ortası.
  final double rotation;
  final DeckAxis? axis;

  /// Kartın şu an yöneldiği karar; hareket yoksa null.
  final DeckDecision? direction;

  /// Eşiğe göre ilerleme: 0 → başlangıç, 1 → eşik, 1'den büyük → eşiği aştı.
  final double progress;

  bool get armed => progress >= 1;

  /// Etiket opaklığı: eşiğe kadar 0→1.
  double get labelOpacity => progress.clamp(0.0, 1.0);

  /// Renk tonu: eşikte en fazla `tintMaxAlpha`.
  double get tintAlpha => SwipePhysics.tintMaxAlpha * labelOpacity;

  @override
  bool operator ==(Object other) =>
      other is SwipeFrame &&
      other.offset == offset &&
      other.rotation == rotation &&
      other.axis == axis &&
      other.direction == direction &&
      other.progress == progress;

  @override
  int get hashCode => Object.hash(offset, rotation, axis, direction, progress);
}

/// Deste fiziği (DESIGN_SYSTEM.md §10 "SwipeDeck" tablosu ve "Fizik" maddesi). Saf hesap;
/// widget'a bağlı değildir ve birim testle doğrulanır.
abstract final class SwipePhysics {
  /// İlk bu kadar harekette baskın eksen seçilir.
  static const double axisLockDistance = 12;

  /// Yatayda kart dönme sınırı (derece).
  static const double maxRotationDegrees = 12;

  /// Aşağı yönde kartın parmağa oranı.
  static const double downResistance = 0.55;

  /// Kilitli eksenin dışına izin verilen en fazla hareket (pt). Yumuşak kilit: ilk hareket
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

  /// Parmağın toplam hareketinden baskın eksen; henüz [axisLockDistance] katedilmediyse null.
  static DeckAxis? lockAxis(Offset finger) {
    if (finger.distance < axisLockDistance) return null;
    return finger.dx.abs() >= finger.dy.abs()
        ? DeckAxis.horizontal
        : DeckAxis.vertical;
  }

  /// Kilitli eksende parmak hareketi → kart ofseti. Ana eksende yatay/yukarı 1:1, aşağı 0,55;
  /// çapraz eksen yumuşak sınırlı.
  static Offset cardOffset(Offset finger, DeckAxis axis) {
    switch (axis) {
      case DeckAxis.horizontal:
        return Offset(finger.dx, softCross(finger.dy));
      case DeckAxis.vertical:
        final main = finger.dy > 0 ? finger.dy * downResistance : finger.dy;
        return Offset(softCross(finger.dx), main);
    }
  }

  /// Kart ofsetinden görsel durum. Dönme yalnızca yatay kilitte; karar ve ilerleme yalnızca
  /// ana eksenden hesaplanır.
  static SwipeFrame frame(Offset offset, DeckAxis? axis, Size card) {
    if (axis == null) return SwipeFrame(offset: offset);
    switch (axis) {
      case DeckAxis.horizontal:
        final dx = offset.dx;
        final maxRad = maxRotationDegrees * math.pi / 180;
        final rotation = (dx / card.width * maxRad).clamp(-maxRad, maxRad);
        final dir = dx == 0
            ? null
            : (dx > 0 ? DeckDecision.ok : DeckDecision.pass);
        return SwipeFrame(
          offset: offset,
          rotation: rotation,
          axis: axis,
          direction: dir,
          progress: dir == null
              ? 0
              : dx.abs() / thresholdOf(DeckDecision.ok, card),
        );
      case DeckAxis.vertical:
        final dy = offset.dy;
        final dir = dy == 0
            ? null
            : (dy < 0 ? DeckDecision.love : DeckDecision.veto);
        return SwipeFrame(
          offset: offset,
          axis: axis,
          direction: dir,
          progress: dir == null ? 0 : dy.abs() / thresholdOf(dir, card),
        );
    }
  }

  /// Bırakınca karar: mesafe veya (↓ hariç) hız. Hız, kartın gittiği yönle aynı olmalı;
  /// çelişiyorsa karar yok, kart geri döner. [velocity] parmağın pt/s hızıdır.
  static DeckDecision? decide({
    required Offset offset,
    required DeckAxis axis,
    required Offset velocity,
    required Size card,
  }) {
    switch (axis) {
      case DeckAxis.horizontal:
        final dx = offset.dx;
        final v = velocity.dx;
        if (dx > 0 &&
            (dx >= thresholdOf(DeckDecision.ok, card) || v > flingVelocity)) {
          return DeckDecision.ok;
        }
        if (dx < 0 &&
            (-dx >= thresholdOf(DeckDecision.pass, card) ||
                -v > flingVelocity)) {
          return DeckDecision.pass;
        }
        return null;
      case DeckAxis.vertical:
        final dy = offset.dy;
        final v = velocity.dy;
        if (dy < 0 &&
            (-dy >= thresholdOf(DeckDecision.love, card) ||
                -v > flingVelocity)) {
          return DeckDecision.love;
        }
        // Olmaz yalnızca mesafeyle; hız tek başına sayılmaz.
        if (dy > 0 && dy >= thresholdOf(DeckDecision.veto, card)) {
          return DeckDecision.veto;
        }
        return null;
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
