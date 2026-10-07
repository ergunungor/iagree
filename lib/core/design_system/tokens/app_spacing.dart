/// 4pt spacing sistemi (DESIGN_SYSTEM.md §5). Yalnızca bu değerler kullanılır.
abstract final class AppSpacing {
  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 40;
  static const double huge = 48;
  static const double giant = 64;

  /// Ekran yatay padding'i (= [lg]).
  static const double screenPadding = 20;

  /// Section arası boşluk (= [xxl]).
  static const double sectionGap = 32;

  /// Kart iç padding'i (= [md]).
  static const double cardPadding = 16;

  /// Minimum dokunma alanı.
  static const double touchTarget = 44;
}
