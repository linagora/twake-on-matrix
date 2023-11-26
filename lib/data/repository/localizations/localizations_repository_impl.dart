import 'dart:ui';

import 'package:fluffychat/data/datasource/localizations/localizations_datasource.dart';
import 'package:fluffychat/domain/repository/localizations/localizations_repository.dart';

class LocalizationsRepositoryImpl extends LocalizationsRepository {
  final LocalizationsDataSource dataSource;

  LocalizationsRepositoryImpl(this.dataSource);

  @override
  Future<void> persistLanguage(Locale localeCurrent) {
    return dataSource.persistLanguage(localeCurrent);
  }
}
