import 'package:dartz/dartz.dart' hide State;
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/config/localizations/localization_service.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/domain/app_state/localizations/save_language_state.dart';
import 'package:fluffychat/domain/usecase/settings/save_language_interactor.dart';
import 'package:fluffychat/pages/settings_dashboard/settings_app_language/settings_app_language_view.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';

class SettingsAppLanguage extends StatefulWidget {
  const SettingsAppLanguage({super.key});

  @override
  State<SettingsAppLanguage> createState() => SettingsAppLanguageController();
}

class SettingsAppLanguageController extends State<SettingsAppLanguage> {
  final saveLanguageInteractor = getIt.get<SaveLanguageInteractor>();

  List<Locale> get supportedLocales {
    final List<Locale> copySupportedLocales =
        List.from(LocalizationService.supportedLocales);

    copySupportedLocales.sort(
      (a, b) => a.languageCode.compareTo(b.languageCode),
    );

    return copySupportedLocales;
  }

  ValueNotifier<Locale> get currentLocale => LocalizationService.currentLocale;

  void changeLanguage(Locale selectedLocale) {
    currentLocale.value = selectedLocale;
    saveLanguageInteractor.execute(selectedLocale).listen(
          (event) => _handleSaveLanguageOnData(context, event),
          onDone: _handleSaveLanguageOnDone,
          onError: _handleSaveLanguageOnError,
        );
  }

  void _handleSaveLanguageOnData(
    BuildContext context,
    Either<Failure, Success> event,
  ) {
    event.fold(
      (failure) => null,
      (success) {
        if (success is SaveLanguageSuccess) {
          LocalizationService.changeLocale(
            context,
            success.localeStored.languageCode,
          );
        }
      },
    );
  }

  void _handleSaveLanguageOnDone() {
    Logs().d('SettingsAppLanguageController::_handleSaveLanguageOnDone()');
  }

  void _handleSaveLanguageOnError(Object error) {
    Logs().e(
      'SettingsAppLanguageController::_handleSaveLanguageOnError():error: $error',
    );
  }

  @override
  Widget build(BuildContext context) {
    return SettingsAppLanguageView(
      controller: this,
    );
  }
}
