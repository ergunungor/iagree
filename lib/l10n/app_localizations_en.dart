// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'iAgree';

  @override
  String get commonLoading => 'Loading';

  @override
  String get commonClear => 'Clear';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonIncrease => 'Increase';

  @override
  String get commonDecrease => 'Decrease';

  @override
  String participantInvited(String name) {
    return '$name, waiting';
  }

  @override
  String participantJoined(String name) {
    return '$name, joined';
  }

  @override
  String participantChoosing(String name, int percent) {
    return '$name, choosing, $percent percent';
  }

  @override
  String participantReady(String name) {
    return '$name, ready';
  }

  @override
  String get commonBack => 'Back';

  @override
  String get commonClose => 'Close';

  @override
  String get offlineBannerMessage =>
      'No connection. Your changes will be sent when you reconnect.';
}
