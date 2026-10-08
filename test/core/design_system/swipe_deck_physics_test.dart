import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:iagree/core/design_system/components/deck/swipe_deck_physics.dart';

const _card = Size(350, 467);
const _screen = Size(390, 844);

DeckDecision? _decide(
  Offset offset,
  DeckAxis axis, [
  Offset velocity = Offset.zero,
]) => SwipePhysics.decide(
  offset: offset,
  axis: axis,
  velocity: velocity,
  card: _card,
);

void main() {
  group('eksen kilidi', () {
    test('12pt altında kilit yok', () {
      expect(SwipePhysics.lockAxis(const Offset(11, 0)), isNull);
      expect(SwipePhysics.lockAxis(const Offset(8, 8)), isNull); // 11,3
    });

    test('12pt\'den sonra baskın eksen', () {
      expect(SwipePhysics.lockAxis(const Offset(12, 3)), DeckAxis.horizontal);
      expect(SwipePhysics.lockAxis(const Offset(-20, 5)), DeckAxis.horizontal);
      expect(SwipePhysics.lockAxis(const Offset(3, -12)), DeckAxis.vertical);
      expect(SwipePhysics.lockAxis(const Offset(2, 30)), DeckAxis.vertical);
    });
  });

  group('takip', () {
    test('yatay 1:1', () {
      final o = SwipePhysics.cardOffset(
        const Offset(80, 0),
        DeckAxis.horizontal,
      );
      expect(o.dx, 80);
      expect(
        SwipePhysics.cardOffset(const Offset(-123, 0), DeckAxis.horizontal).dx,
        -123,
      );
    });

    test('yukarı 1:1', () {
      expect(
        SwipePhysics.cardOffset(const Offset(0, -90), DeckAxis.vertical).dy,
        -90,
      );
    });

    test('aşağı parmağın 0,55\'i', () {
      expect(
        SwipePhysics.cardOffset(const Offset(0, 100), DeckAxis.vertical).dy,
        closeTo(55, 1e-9),
      );
      expect(SwipePhysics.downResistance, 0.55);
    });

    test('mapping 0 noktasında sürekli (yukarı/aşağı arası sıçrama yok)', () {
      final up = SwipePhysics.cardOffset(
        const Offset(0, -0.001),
        DeckAxis.vertical,
      );
      final down = SwipePhysics.cardOffset(
        const Offset(0, 0.001),
        DeckAxis.vertical,
      );
      expect((up.dy - down.dy).abs(), lessThan(0.01));
    });
  });

  group('yumuşak kilit (çapraz eksen)', () {
    test('küçük harekette ~1:1', () {
      final v = SwipePhysics.softCross(2);
      expect(v, closeTo(2, 0.05));
    });

    test('sınırı (24pt) asla aşmaz, simetrik, monoton', () {
      var last = 0.0;
      for (var d = 1.0; d <= 2000; d += 7) {
        final v = SwipePhysics.softCross(d);
        expect(v, lessThanOrEqualTo(24));
        expect(v, greaterThanOrEqualTo(last - 1e-9));
        expect(SwipePhysics.softCross(-d), closeTo(-v, 1e-9));
        last = v;
      }
      expect(SwipePhysics.softCross(5000), closeTo(24, 1e-6));
    });

    test('yatay kilitte dikey sapma sınırlı, ana eksen etkilenmez', () {
      final o = SwipePhysics.cardOffset(
        const Offset(200, 300),
        DeckAxis.horizontal,
      );
      expect(o.dx, 200);
      expect(o.dy, lessThanOrEqualTo(24));
      expect(o.dy, greaterThan(20));
    });

    test('dikey kilitte yatay sapma sınırlı', () {
      final o = SwipePhysics.cardOffset(
        const Offset(-300, -100),
        DeckAxis.vertical,
      );
      expect(o.dy, -100);
      expect(o.dx.abs(), lessThanOrEqualTo(24));
    });

    test('çapraz hareket kararı ve dönmeyi etkilemez', () {
      final f = SwipePhysics.frame(
        const Offset(0, -60),
        DeckAxis.vertical,
        _card,
      );
      final g = SwipePhysics.frame(
        const Offset(20, -60),
        DeckAxis.vertical,
        _card,
      );
      expect(f.progress, g.progress);
      expect(f.direction, g.direction);
      expect(g.rotation, 0);
      final h = SwipePhysics.frame(
        const Offset(80, 0),
        DeckAxis.horizontal,
        _card,
      );
      final i = SwipePhysics.frame(
        const Offset(80, 20),
        DeckAxis.horizontal,
        _card,
      );
      expect(h.progress, i.progress);
      expect(h.rotation, i.rotation);
    });
  });

  group('dönme', () {
    double deg(double r) => r * 180 / math.pi;

    test('(dx / genişlik) × 12°', () {
      final f = SwipePhysics.frame(
        const Offset(87.5, 0),
        DeckAxis.horizontal,
        _card,
      );
      expect(deg(f.rotation), closeTo(3, 1e-9)); // 87.5/350 = .25 → 3°
      final g = SwipePhysics.frame(
        const Offset(-175, 0),
        DeckAxis.horizontal,
        _card,
      );
      expect(deg(g.rotation), closeTo(-6, 1e-9));
    });

    test('en fazla ±12°', () {
      for (final dx in [350.0, 500.0, 1000.0]) {
        expect(
          deg(
            SwipePhysics.frame(
              Offset(dx, 0),
              DeckAxis.horizontal,
              _card,
            ).rotation,
          ),
          closeTo(12, 1e-9),
        );
        expect(
          deg(
            SwipePhysics.frame(
              Offset(-dx, 0),
              DeckAxis.horizontal,
              _card,
            ).rotation,
          ),
          closeTo(-12, 1e-9),
        );
      }
    });

    test('dikey kilitte dönme yok', () {
      expect(
        SwipePhysics.frame(
          const Offset(0, -200),
          DeckAxis.vertical,
          _card,
        ).rotation,
        0,
      );
      expect(
        SwipePhysics.frame(
          const Offset(0, 120),
          DeckAxis.vertical,
          _card,
        ).rotation,
        0,
      );
    });
  });

  group('eşikler: mesafe', () {
    test('→ ve ← kart genişliğinin %30\'u', () {
      expect(
        SwipePhysics.thresholdOf(DeckDecision.ok, _card),
        closeTo(105, 1e-9),
      );
      expect(_decide(const Offset(104.9, 0), DeckAxis.horizontal), isNull);
      expect(
        _decide(const Offset(105, 0), DeckAxis.horizontal),
        DeckDecision.ok,
      );
      expect(_decide(const Offset(-104.9, 0), DeckAxis.horizontal), isNull);
      expect(
        _decide(const Offset(-105, 0), DeckAxis.horizontal),
        DeckDecision.pass,
      );
    });

    test('↑ yüksekliğin %25\'i', () {
      expect(
        SwipePhysics.thresholdOf(DeckDecision.love, _card),
        closeTo(116.75, 1e-9),
      );
      expect(_decide(const Offset(0, -116.7), DeckAxis.vertical), isNull);
      expect(
        _decide(const Offset(0, -116.75), DeckAxis.vertical),
        DeckDecision.love,
      );
    });

    test('↓ yüksekliğin %35\'i (kartın görünen ofseti)', () {
      expect(
        SwipePhysics.thresholdOf(DeckDecision.veto, _card),
        closeTo(163.45, 1e-9),
      );
      expect(_decide(const Offset(0, 163.4), DeckAxis.vertical), isNull);
      expect(
        _decide(const Offset(0, 163.45), DeckAxis.vertical),
        DeckDecision.veto,
      );
      // Parmak mesafesi: 163,45 / 0,55 ≈ %64 yükseklik gerekir.
      final fingerNeeded = 163.45 / 0.55;
      expect(fingerNeeded / _card.height, closeTo(0.636, 0.001));
    });
  });

  group('eşikler: hız', () {
    test('→ ← ↑ için 800 pt/s üstü karar sayılır (mesafe az olsa da)', () {
      expect(
        _decide(const Offset(20, 0), DeckAxis.horizontal, const Offset(801, 0)),
        DeckDecision.ok,
      );
      expect(
        _decide(const Offset(20, 0), DeckAxis.horizontal, const Offset(799, 0)),
        isNull,
      );
      expect(
        _decide(
          const Offset(-20, 0),
          DeckAxis.horizontal,
          const Offset(-801, 0),
        ),
        DeckDecision.pass,
      );
      expect(
        _decide(const Offset(0, -20), DeckAxis.vertical, const Offset(0, -801)),
        DeckDecision.love,
      );
      expect(
        _decide(const Offset(0, -20), DeckAxis.vertical, const Offset(0, -799)),
        isNull,
      );
    });

    test('Olmaz yalnızca mesafeyle: hız tek başına sayılmaz', () {
      expect(
        _decide(const Offset(0, 30), DeckAxis.vertical, const Offset(0, 5000)),
        isNull,
      );
      expect(
        _decide(const Offset(0, 163.45), DeckAxis.vertical, Offset.zero),
        DeckDecision.veto,
      );
    });

    test('hız yönü ofsetle çelişirse karar yok', () {
      expect(
        _decide(
          const Offset(60, 0),
          DeckAxis.horizontal,
          const Offset(-2000, 0),
        ),
        isNull,
      );
      expect(
        _decide(
          const Offset(-60, 0),
          DeckAxis.horizontal,
          const Offset(2000, 0),
        ),
        isNull,
      );
      expect(
        _decide(const Offset(0, -60), DeckAxis.vertical, const Offset(0, 2000)),
        isNull,
      );
    });

    test('hiç hareket yokken hızlı bırakma karar vermez', () {
      expect(
        _decide(Offset.zero, DeckAxis.horizontal, const Offset(3000, 0)),
        isNull,
      );
    });

    test('çapraz hız karar vermez', () {
      expect(
        _decide(
          const Offset(20, 0),
          DeckAxis.horizontal,
          const Offset(0, -3000),
        ),
        isNull,
      );
    });
  });

  group('etiket opaklığı ve renk tonu', () {
    test('opaklık eşiğe kadar 0→1, sonra 1', () {
      double op(double dx) => SwipePhysics.frame(
        Offset(dx, 0),
        DeckAxis.horizontal,
        _card,
      ).labelOpacity;
      expect(op(0), 0);
      expect(op(52.5), closeTo(0.5, 1e-9));
      expect(op(105), 1);
      expect(op(300), 1);
    });

    test('ton eşikte en fazla %20', () {
      double tint(double dy) =>
          SwipePhysics.frame(Offset(0, dy), DeckAxis.vertical, _card).tintAlpha;
      expect(tint(0), 0);
      expect(tint(-58.375), closeTo(0.10, 1e-9));
      expect(tint(-116.75), closeTo(0.20, 1e-9));
      expect(tint(-400), closeTo(0.20, 1e-9));
    });

    test('yön işareti: yatay ±, dikey ↑ love ↓ veto', () {
      DeckDecision? d(Offset o, DeckAxis a) =>
          SwipePhysics.frame(o, a, _card).direction;
      expect(d(const Offset(10, 0), DeckAxis.horizontal), DeckDecision.ok);
      expect(d(const Offset(-10, 0), DeckAxis.horizontal), DeckDecision.pass);
      expect(d(const Offset(0, -10), DeckAxis.vertical), DeckDecision.love);
      expect(d(const Offset(0, 10), DeckAxis.vertical), DeckDecision.veto);
      expect(d(Offset.zero, DeckAxis.vertical), isNull);
    });

    test('eşiğe girince armed; ↓ ilerlemesi kartın görünen ofsetine göre', () {
      expect(
        SwipePhysics.frame(
          const Offset(104, 0),
          DeckAxis.horizontal,
          _card,
        ).armed,
        isFalse,
      );
      expect(
        SwipePhysics.frame(
          const Offset(105, 0),
          DeckAxis.horizontal,
          _card,
        ).armed,
        isTrue,
      );
      expect(
        SwipePhysics.frame(
          const Offset(0, 163.45),
          DeckAxis.vertical,
          _card,
        ).armed,
        isTrue,
      );
    });

    test('kilitten önce etiket yok', () {
      final f = SwipePhysics.frame(const Offset(5, 3), null, _card);
      expect(f.direction, isNull);
      expect(f.progress, 0);
      expect(f.rotation, 0);
    });
  });

  group('uçuş', () {
    test('hedef: karar yönünde ekran dışı, çapraz eksen korunur', () {
      expect(
        SwipePhysics.flyTarget(DeckDecision.ok, const Offset(120, 10), _screen),
        const Offset(390, 10),
      );
      expect(
        SwipePhysics.flyTarget(
          DeckDecision.pass,
          const Offset(-120, 4),
          _screen,
        ),
        const Offset(-390, 4),
      );
      expect(
        SwipePhysics.flyTarget(
          DeckDecision.love,
          const Offset(6, -130),
          _screen,
        ),
        const Offset(6, -844),
      );
      expect(
        SwipePhysics.flyTarget(
          DeckDecision.veto,
          const Offset(-6, 170),
          _screen,
        ),
        const Offset(-6, 844),
      );
    });

    const min = Duration(milliseconds: 120);
    const max = Duration(milliseconds: 225);

    test('yavaş bırakma: mesafe/1000, üst sınıra kıstırılır', () {
      expect(
        SwipePhysics.flyDuration(distance: 285, speed: 0, min: min, max: max),
        const Duration(milliseconds: 225),
      );
      expect(
        SwipePhysics.flyDuration(distance: 160, speed: 300, min: min, max: max),
        const Duration(milliseconds: 160),
      );
    });

    test('hızlı fırlatma kısa sürer, alt sınıra kıstırılır', () {
      expect(
        SwipePhysics.flyDuration(
          distance: 285,
          speed: 2000,
          min: min,
          max: max,
        ),
        const Duration(milliseconds: 142, microseconds: 500),
      );
      expect(
        SwipePhysics.flyDuration(
          distance: 200,
          speed: 9000,
          min: min,
          max: max,
        ),
        min,
      );
    });

    test('hız negatif de olsa büyüklüğü sayılır; min 1000 pt/s', () {
      expect(
        SwipePhysics.flyDuration(
          distance: 100,
          speed: -50,
          min: Duration.zero,
          max: max,
        ),
        const Duration(milliseconds: 100),
      );
    });

    test('Reduce Motion (min = max = 0): süre 0', () {
      expect(
        SwipePhysics.flyDuration(
          distance: 300,
          speed: 100,
          min: Duration.zero,
          max: Duration.zero,
        ),
        Duration.zero,
      );
    });
  });
}
