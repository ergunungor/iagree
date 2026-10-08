import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Cihaza özel ayarlar. Şimdilik yalnızca görünüm (Sistem/Açık/Koyu); `shared_preferences`
/// ile saklanır. Depolama erişilemezse (test, bozuk disk) varsayılana düşer ve çökmez.
class SettingsController extends ChangeNotifier {
  SettingsController();

  static const String _themeKey = 'themeMode';

  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
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
}
