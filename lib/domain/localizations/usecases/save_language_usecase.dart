import 'dart:ui';

import 'package:twake_chat/domain/localizations/exceptions/save_language_exception.dart';
import 'package:twake_chat/domain/repository/localizations/localizations_repository.dart';

class SaveLanguageUseCase {
  const SaveLanguageUseCase(this._repository);

  final LocalizationsRepository _repository;

  Future<void> execute(Locale locale) async {
    try {
      await _repository.persistLanguage(locale);
    } catch (e, s) {
      Error.throwWithStackTrace(SaveLanguageException(e), s);
    }
  }
}
