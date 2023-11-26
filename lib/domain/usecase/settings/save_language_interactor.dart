import 'dart:core';
import 'dart:ui';

import 'package:dartz/dartz.dart';
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/domain/app_state/localizations/save_language_state.dart';
import 'package:fluffychat/domain/repository/localizations/localizations_repository.dart';

class SaveLanguageInteractor {
  final LocalizationsRepository localizationsRepository;

  SaveLanguageInteractor(this.localizationsRepository);

  Stream<Either<Failure, Success>> execute(Locale localeCurrent) async* {
    try {
      yield Right(SavingLanguage());
      await localizationsRepository.persistLanguage(localeCurrent);
      yield Right(SaveLanguageSuccess(localeCurrent));
    } catch (exception) {
      yield Left(SaveLanguageFailure(exception));
    }
  }
}
