import 'dart:ui';

import 'package:fluffychat/data/datasource/localizations/localizations_datasource.dart';
import 'package:fluffychat/data/local/localizations/language_cache_manager.dart';

class LocalizationsDataSourceImpl extends LocalizationsDataSource {
  final LanguageCacheManager _languageCacheManager;

  LocalizationsDataSourceImpl(
    this._languageCacheManager,
  );

  @override
  Future<void> persistLanguage(Locale localeCurrent) {
    return _languageCacheManager.persistLanguage(localeCurrent);
  }
}
