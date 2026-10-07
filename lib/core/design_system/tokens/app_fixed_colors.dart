import 'package:flutter/painting.dart';

/// İki temada aynı olan renkler (moment* ve inverse*). Değerler tokens.json'dan birebir.
abstract final class AppFixedColors {
  static const Color momentBg = Color(0xFF6B2E63);
  static const Color momentInk = Color(0xFFFAF7F2);
  static const Color momentTrack = Color(0x33FAF7F2);
  static const Color momentGhost = Color(0x26FAF7F2);
  static const Color inverseSurface = Color(0xFF29242E);
  static const Color inverseText = Color(0xFFF4EFF2);
  static const Color inverseAction = Color(0xFFD59AD0);
  static const Color inverseSuccess = Color(0xFF52C48D);
  static const Color inverseError = Color(0xFFFF7F76);
}
