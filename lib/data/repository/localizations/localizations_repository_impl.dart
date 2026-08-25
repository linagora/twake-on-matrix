import 'dart:ui';

import 'package:twake_chat/data/datasource/localizations/localizations_datasource.dart';
import 'package:twake_chat/domain/repository/localizations/localizations_repository.dart';

class LocalizationsRepositoryImpl extends LocalizationsRepository {
  final LocalizationsDataSource dataSource;

  LocalizationsRepositoryImpl(this.dataSource);

  @override
  Future<void> persistLanguage(Locale localeCurrent) {
    return dataSource.persistLanguage(localeCurrent);
  }
}
