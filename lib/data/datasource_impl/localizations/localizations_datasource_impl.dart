import 'dart:ui';

import 'package:twake_chat/data/datasource/localizations/localizations_datasource.dart';
import 'package:twake_chat/data/local/localizations/language_cache_manager.dart';

class LocalizationsDataSourceImpl extends LocalizationsDataSource {
  final LanguageCacheManager _languageCacheManager;

  LocalizationsDataSourceImpl(this._languageCacheManager);

  @override
  Future<void> persistLanguage(Locale localeCurrent) {
    return _languageCacheManager.persistLanguage(localeCurrent);
  }
}
