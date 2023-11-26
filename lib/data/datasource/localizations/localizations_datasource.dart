import 'dart:ui';

abstract class LocalizationsDataSource {
  Future<void> persistLanguage(Locale localeCurrent);
}
