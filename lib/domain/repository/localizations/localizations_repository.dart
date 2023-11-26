import 'dart:ui';

abstract class LocalizationsRepository {
  Future<void> persistLanguage(Locale localeCurrent);
}
