import 'dart:ui';

import 'package:twake_chat/domain/repository/localizations/localizations_repository.dart';

class FakeLocalizationsRepository extends LocalizationsRepository {
  FakeLocalizationsRepository({this.onPersistLanguage});

  final Future<void> Function(Locale locale)? onPersistLanguage;

  final List<Locale> calls = [];

  @override
  Future<void> persistLanguage(Locale localeCurrent) async {
    calls.add(localeCurrent);
    await onPersistLanguage?.call(localeCurrent);
  }
}
