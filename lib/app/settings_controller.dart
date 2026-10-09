import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Cihaza özel ayarlar. Şimdilik yalnızca görünüm (Sistem/Açık/Koyu); `shared_preferences`
/// ile saklanır. Depolama erişilemezse (test, bozuk disk) varsayılana düşer ve çökmez.
class SettingsController extends ChangeNotifier {
  SettingsController();

  static const String _themeKey = 'themeMode';
  static const String _deckHintKey = 'deckHintSeen';
  static const String _notifyKey = 'notificationPromptSeen';

  ThemeMode _themeMode = ThemeMode.system;

  bool _deckHintSeen = false;
  bool _notificationPromptSeen = false;

  ThemeMode get themeMode => _themeMode;

  /// İlk kullanım ipucu (dört yön) bir kez gösterilir.
  bool get deckHintSeen => _deckHintSeen;

  /// Bildirim kartı bir kez gösterilir (cevap ne olursa olsun, bir daha çıkmaz).
  bool get notificationPromptSeen => _notificationPromptSeen;

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _deckHintSeen = prefs.getBool(_deckHintKey) ?? false;
      _notificationPromptSeen = prefs.getBool(_notifyKey) ?? false;
      final stored = prefs.getString(_themeKey);
      final mode = ThemeMode.values.where((m) => m.name == stored);
      if (mode.isNotEmpty && mode.first != _themeMode) {
        _themeMode = mode.first;
        notifyListeners();
      }
    } on Object {
      // Varsayılan görünümle devam.
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (mode == _themeMode) return;
    _themeMode = mode;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_themeKey, mode.name);
    } on Object {
      // Kaydedilemedi; bu oturumda geçerli kalır.
    }
  }

  Future<void> markDeckHintSeen() async {
    if (_deckHintSeen) return;
    _deckHintSeen = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_deckHintKey, true);
    } on Object {
      // Kaydedilemedi; bu oturumda tekrar gösterilmez.
    }
  }

  Future<void> markNotificationPromptSeen() async {
    if (_notificationPromptSeen) return;
    _notificationPromptSeen = true;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_notifyKey, true);
    } on Object {
      // Kaydedilemedi; bu oturumda tekrar gösterilmez.
    }
  }
}
