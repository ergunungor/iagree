import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:iagree/core/design_system/components/agreement/agreement_math.dart';

int _p(int love, int ok, int total) =>
    AgreementMath.percent(loveCount: love, okCount: ok, total: total);

void main() {
  group('yüzde', () {
    test('(Olur + Çok isterim) / toplam; ağırlıklı skor yok', () {
      expect(_p(0, 4, 5), 80);
      expect(_p(4, 0, 5), 80);
      expect(_p(2, 2, 5), 80);
      expect(_p(1, 1, 4), 50);
      expect(_p(0, 0, 5), 0);
    });

    test('yukarı yuvarlama yok: aşağı yuvarlanır', () {
      expect(_p(0, 2, 3), 66); // 66,67 → 66
      expect(_p(0, 1, 3), 33);
      expect(_p(0, 199, 200), 99);
      expect(_p(0, 995, 1000), 99);
      expect(_p(0, 6, 7), 85); // 85,71 → 85
    });

    test('%100 yalnızca herkes olumluysa', () {
      expect(_p(0, 5, 5), 100);
      expect(_p(3, 2, 5), 100);
      expect(_p(0, 1, 1), 100);
      for (var total = 1; total <= 300; total++) {
        expect(_p(0, total - 1, total) < 100, isTrue, reason: '$total');
        expect(_p(0, total, total), 100, reason: '$total');
      }
    });

    test('hiç kişi yoksa 0, sıfıra bölme yok', () {
      expect(_p(0, 0, 0), 0);
    });

    test('girdi doğrulanır', () {
      expect(() => _p(-1, 0, 5), throwsAssertionError);
      expect(() => _p(0, 6, 5), throwsAssertionError);
      expect(() => _p(3, 3, 5), throwsAssertionError);
    });
  });

  group('yay dilimleri', () {
    const r = 29.0;
    const w = 6.0;
    final arcLen = r * math.pi;

    List<ArcSegment> segs(int love, int ok, int total, {bool single = false}) =>
        arcSegments(
          loveCount: love,
          okCount: ok,
          total: total,
          radius: r,
          strokeWidth: w,
          singleTone: single,
        );

    test('kimse olumlu değilse dilim yok', () {
      expect(segs(0, 0, 5), isEmpty);
      expect(segs(0, 0, 0), isEmpty);
    });

    test('tek ton paylar boşluksuz tek dilim; renk payın kendisi', () {
      expect(segs(2, 0, 4), [const ArcSegment(0, 0.5, ArcTone.love)]);
      expect(segs(0, 3, 4), [const ArcSegment(0, 0.75, ArcTone.ok)]);
    });

    test('iki pay: sol Çok isterim, sağ Olur; görsel boşluk 2pt', () {
      final s = segs(2, 2, 5);
      expect(s, hasLength(2));
      expect(s[0].tone, ArcTone.love);
      expect(s[1].tone, ArcTone.ok);
      // Yuvarlak uçlar w/2 taşar: görünür boşluk = merkez çizgisi aralığı − w.
      final centerGap = (s[1].start - s[0].end) * arcLen;
      expect(centerGap - w, closeTo(2, 1e-9));
      // Dış uçlar payların gerçek sınırında: toplam pay korunur.
      expect(s[0].start, 0);
      expect(s[1].end, closeTo(0.8, 1e-12));
    });

    test('sınır, boşluğun tam ortasında', () {
      final s = segs(2, 2, 5);
      expect((s[0].end + s[1].start) / 2, closeTo(0.4, 1e-12));
    });

    test('çok küçük dilim eksiye düşmez, noktaya iner', () {
      final s = segs(1, 199, 200);
      expect(s[0].end - s[0].start, greaterThanOrEqualTo(0));
      expect(s[1].end, greaterThanOrEqualTo(s[1].start));
      final s2 = segs(199, 1, 200);
      expect(s2[1].end - s2[1].start, greaterThanOrEqualTo(0));
    });

    test('karar anı: tek ton, tek dilim, boşluk yok', () {
      expect(segs(2, 2, 5, single: true), [
        const ArcSegment(0, 0.8, ArcTone.love),
      ]);
    });

    test('dilimler birbirini aşmaz ve 0–1 içinde kalır', () {
      for (var total = 1; total <= 12; total++) {
        for (var love = 0; love <= total; love++) {
          for (var ok = 0; love + ok <= total; ok++) {
            final s = segs(love, ok, total);
            for (final x in s) {
              expect(x.start, inInclusiveRange(0, 1));
              expect(x.end, inInclusiveRange(0, 1.0000001));
              expect(x.end, greaterThanOrEqualTo(x.start));
            }
            if (s.length == 2) {
              expect(s[1].start, greaterThanOrEqualTo(s[0].end));
            }
          }
        }
      }
    });
  });
}
