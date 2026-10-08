import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:iagree/core/design_system/components/deck/swipe_deck_physics.dart';

const _card = Size(350, 467);
const _screen = Size(390, 844);

DeckDecision? _decide(Offset offset, [Offset velocity = Offset.zero]) =>
    SwipePhysics.decide(offset: offset, velocity: velocity, card: _card);

SwipeFrame _frame(Offset o) => SwipePhysics.frame(o, _card);

void main() {
  group('takip (eksen kilitli değil)', () {
    test('saf yatay: 1:1, dikey sapma yok', () {
      expect(SwipePhysics.cardOffset(const Offset(80, 0)), const Offset(80, 0));
      expect(SwipePhysics.cardOffset(const Offset(-123, 0)).dx, -123);
    });

    test('saf yukarı 1:1', () {
      expect(
        SwipePhysics.cardOffset(const Offset(0, -90)),
        const Offset(0, -90),
      );
    });

    test('saf aşağı parmağın 0,55\'i', () {
      expect(
        SwipePhysics.cardOffset(const Offset(0, 100)).dy,
        closeTo(55, 1e-9),
      );
      expect(SwipePhysics.downResistance, 0.55);
    });

    test('0 noktasında sürekli (yukarı/aşağı arası sıçrama yok)', () {
      final up = SwipePhysics.cardOffset(const Offset(0, -0.001));
      final down = SwipePhysics.cardOffset(const Offset(0, 0.001));
      expect((up.dy - down.dy).abs(), lessThan(0.01));
    });

    test('baskın eksende diğer eksen sınırlı (24pt)', () {
      final h = SwipePhysics.cardOffset(const Offset(200, 20));
      expect(h.dx, 200);
      expect(h.dy.abs(), lessThanOrEqualTo(24));
      final v = SwipePhysics.cardOffset(const Offset(15, -200));
      expect(v.dy, -200);
      expect(v.dx.abs(), lessThanOrEqualTo(24));
    });

    test(
      'softCross: küçük harekette ~1:1, sınırı aşmaz, simetrik, monoton',
      () {
        expect(SwipePhysics.softCross(2), closeTo(2, 0.05));
        var last = 0.0;
        for (var d = 1.0; d <= 2000; d += 7) {
          final v = SwipePhysics.softCross(d);
          expect(v, lessThanOrEqualTo(24));
          expect(v, greaterThanOrEqualTo(last - 1e-9));
          expect(SwipePhysics.softCross(-d), closeTo(-v, 1e-9));
          last = v;
        }
        expect(SwipePhysics.softCross(5000), closeTo(24, 1e-6));
      },
    );
  });

  group('bırakmadan eksen değiştirme', () {
    test(
      'yatayda başlayıp yukarı çıkınca kart yukarıya gelir, yön değişir',
      () {
        // Parmak önce sağa 100pt, sonra dx sabit kalıp yukarı 200pt çıkar.
        final right = SwipePhysics.cardOffset(const Offset(100, 0));
        final up = SwipePhysics.cardOffset(const Offset(100, -300));
        expect(right.dx, 100);
        expect(_frame(right).direction, DeckDecision.ok);
        expect(up.dy, -300);
        expect(up.dx, lessThanOrEqualTo(24)); // yatay hareket geri çekildi
        expect(_frame(up).direction, DeckDecision.love);
      },
    );

    test('yukarıda başlayıp yatay döndürmek de mümkün', () {
      final up = SwipePhysics.cardOffset(const Offset(0, -80));
      final right = SwipePhysics.cardOffset(const Offset(220, -80));
      expect(_frame(up).direction, DeckDecision.love);
      expect(right.dx, 220);
      expect(_frame(right).direction, DeckDecision.ok);
    });

    test(
      'geçiş sürekli: parmak 1pt hareket edince kart 3pt\'den fazla sıçramaz',
      () {
        // Parmağın izlediği yol: sağa 100, sonra yukarı 250; sonra sola 300.
        final path = <Offset>[
          for (var x = 0.0; x <= 100; x++) Offset(x, 0),
          for (var y = 0.0; y >= -250; y--) Offset(100, y),
          for (var x = 100.0; x >= -200; x--) Offset(x, -250),
          for (var y = -250.0; y <= 200; y++)
            const Offset(-200, 0) + Offset(0, y),
        ];
        var worst = 0.0;
        for (var i = 1; i < path.length; i++) {
          final a = SwipePhysics.cardOffset(path[i - 1]);
          final b = SwipePhysics.cardOffset(path[i]);
          worst = math.max(worst, (b - a).distance);
        }
        expect(worst, lessThan(3));
      },
    );

    test('etiket yönü yolda sırayla: Olur → Çok isterim → Pas → Olmaz', () {
      DeckDecision? at(Offset finger) =>
          _frame(SwipePhysics.cardOffset(finger)).direction;
      expect(at(const Offset(100, 0)), DeckDecision.ok);
      expect(at(const Offset(100, -220)), DeckDecision.love);
      expect(at(const Offset(-300, -100)), DeckDecision.pass);
      expect(at(const Offset(-150, 420)), DeckDecision.veto);
    });

    test(
      'bırakınca karar son konuma göre: sağa çekip yukarı çıkan → Çok isterim',
      () {
        final offset = SwipePhysics.cardOffset(const Offset(100, -200));
        expect(_decide(offset), DeckDecision.love);
        // Aynı yolda yukarı çıkmadan bırakılsa Olur olurdu.
        expect(
          _decide(SwipePhysics.cardOffset(const Offset(120, 0))),
          DeckDecision.ok,
        );
      },
    );
  });

  group('dönme', () {
    double deg(double r) => r * 180 / math.pi;

    test('yatayda (dx / genişlik) × 12°', () {
      expect(deg(_frame(const Offset(87.5, 0)).rotation), closeTo(3, 1e-9));
      expect(deg(_frame(const Offset(-175, 0)).rotation), closeTo(-6, 1e-9));
    });

    test('en fazla ±12°', () {
      for (final dx in [350.0, 500.0, 1000.0]) {
        expect(deg(_frame(Offset(dx, 0)).rotation), closeTo(12, 1e-9));
        expect(deg(_frame(Offset(-dx, 0)).rotation), closeTo(-12, 1e-9));
      }
    });

    test('dikey baskınken dönme yok, geçişte yumuşakça azalır', () {
      expect(_frame(const Offset(0, -200)).rotation, 0);
      expect(_frame(const Offset(0, 120)).rotation, 0);
      expect(_frame(const Offset(10, -200)).rotation.abs(), lessThan(0.001));
      final mid = _frame(const Offset(100, -88)).rotation.abs(); // |a−b| = 12
      final full = _frame(const Offset(100, 0)).rotation.abs();
      expect(mid, lessThan(full));
      expect(mid, greaterThan(0));
    });
  });

  group('yön ve etiket', () {
    test('12pt\'den az harekette yön yok', () {
      expect(_frame(const Offset(11, 0)).direction, isNull);
      expect(_frame(Offset.zero).progress, 0);
    });

    test('yön, eşiğe göre daha ilerlemiş eksenin yönü', () {
      expect(_frame(const Offset(30, 5)).direction, DeckDecision.ok);
      expect(_frame(const Offset(-30, 5)).direction, DeckDecision.pass);
      expect(_frame(const Offset(5, -30)).direction, DeckDecision.love);
      expect(_frame(const Offset(5, 30)).direction, DeckDecision.veto);
    });

    test('opaklık eşiğe kadar 0→1, sonra 1', () {
      double op(double dx) => _frame(Offset(dx, 0)).labelOpacity;
      expect(op(52.5), closeTo(0.5, 1e-9));
      expect(op(105), 1);
      expect(op(300), 1);
    });

    test('ton eşikte en fazla %20', () {
      double tint(double dy) => _frame(Offset(0, dy)).tintAlpha;
      expect(tint(-58.375), closeTo(0.10, 1e-9));
      expect(tint(-116.75), closeTo(0.20, 1e-9));
      expect(tint(-400), closeTo(0.20, 1e-9));
    });

    test('armed: eşiğe girince; ↓ ilerlemesi kartın görünen ofsetine göre', () {
      expect(_frame(const Offset(104, 0)).armed, isFalse);
      expect(_frame(const Offset(105, 0)).armed, isTrue);
      expect(_frame(const Offset(0, 163.45)).armed, isTrue);
      expect(_frame(const Offset(0, 163.4)).armed, isFalse);
    });
  });

  group('eşikler: mesafe', () {
    test('→ ve ← kart genişliğinin %30\'u', () {
      expect(
        SwipePhysics.thresholdOf(DeckDecision.ok, _card),
        closeTo(105, 1e-9),
      );
      expect(_decide(const Offset(104.9, 0)), isNull);
      expect(_decide(const Offset(105, 0)), DeckDecision.ok);
      expect(_decide(const Offset(-104.9, 0)), isNull);
      expect(_decide(const Offset(-105, 0)), DeckDecision.pass);
    });

    test('↑ yüksekliğin %25\'i', () {
      expect(
        SwipePhysics.thresholdOf(DeckDecision.love, _card),
        closeTo(116.75, 1e-9),
      );
      expect(_decide(const Offset(0, -116.7)), isNull);
      expect(_decide(const Offset(0, -116.75)), DeckDecision.love);
    });

    test('↓ yüksekliğin %35\'i (kartın görünen ofseti)', () {
      expect(
        SwipePhysics.thresholdOf(DeckDecision.veto, _card),
        closeTo(163.45, 1e-9),
      );
      expect(_decide(const Offset(0, 163.4)), isNull);
      expect(_decide(const Offset(0, 163.45)), DeckDecision.veto);
      expect(163.45 / 0.55 / _card.height, closeTo(0.636, 0.001));
    });
  });

  group('eşikler: hız', () {
    test('→ ← ↑ için 800 pt/s üstü karar sayılır (mesafe az olsa da)', () {
      expect(
        _decide(const Offset(20, 0), const Offset(801, 0)),
        DeckDecision.ok,
      );
      expect(_decide(const Offset(20, 0), const Offset(799, 0)), isNull);
      expect(
        _decide(const Offset(-20, 0), const Offset(-801, 0)),
        DeckDecision.pass,
      );
      expect(
        _decide(const Offset(0, -20), const Offset(0, -801)),
        DeckDecision.love,
      );
      expect(_decide(const Offset(0, -20), const Offset(0, -799)), isNull);
    });

    test('Olmaz yalnızca mesafeyle: hız tek başına sayılmaz', () {
      expect(_decide(const Offset(0, 30), const Offset(0, 5000)), isNull);
      expect(_decide(const Offset(0, 163.45)), DeckDecision.veto);
    });

    test('hız yönü ofsetle çelişirse karar yok', () {
      expect(_decide(const Offset(60, 0), const Offset(-2000, 0)), isNull);
      expect(_decide(const Offset(-60, 0), const Offset(2000, 0)), isNull);
      expect(_decide(const Offset(0, -60), const Offset(0, 2000)), isNull);
    });

    test('kart 12pt\'den az oynadıysa hızlı bırakma karar vermez', () {
      expect(_decide(Offset.zero, const Offset(3000, 0)), isNull);
      expect(_decide(const Offset(8, 0), const Offset(3000, 0)), isNull);
    });

    test('baskın eksen yetmezse diğer eksendeki hızlı fırlatma da denenir', () {
      // Yatay baskın (60, −20) ama bırakırken yukarı hızlı: Çok isterim.
      expect(
        _decide(const Offset(60, -20), const Offset(0, -1500)),
        DeckDecision.love,
      );
      // Yatay hızlıysa Olur.
      expect(
        _decide(const Offset(60, -20), const Offset(1500, 0)),
        DeckDecision.ok,
      );
    });

    test('çapraz hız, o eksende hareket yoksa karar vermez', () {
      expect(_decide(const Offset(20, 0), const Offset(0, -3000)), isNull);
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
