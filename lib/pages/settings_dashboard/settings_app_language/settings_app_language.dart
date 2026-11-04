import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:matrix/matrix.dart';
import 'package:twake_chat/config/localizations/localization_service.dart';
import 'package:twake_chat/domain/localizations/usecases/save_language_usecase.provider.dart';
import 'package:twake_chat/pages/settings_dashboard/settings_app_language/settings_app_language_view.dart';

class SettingsAppLanguage extends ConsumerStatefulWidget {
  const SettingsAppLanguage({super.key});

  @override
  ConsumerState<SettingsAppLanguage> createState() =>
      SettingsAppLanguageController();
}

class SettingsAppLanguageController extends ConsumerState<SettingsAppLanguage> {
  List<Locale> get supportedLocales {
    final List<Locale> copySupportedLocales = List.from(
      LocalizationService.supportedLocales,
    );

    copySupportedLocales.sort(
      (a, b) => a.languageCode.compareTo(b.languageCode),
    );

    return copySupportedLocales;
  }

  // TODO: [transitional] The current locale is still owned by LocalizationService.
  ValueNotifier<Locale> get currentLocale => LocalizationService.currentLocale;

  Future<void> changeLanguage(Locale selectedLocale) async {
    currentLocale.value = selectedLocale;
    try {
      await ref.read(saveLanguageUseCaseProvider).execute(selectedLocale);
    } catch (e, s) {
      Logs().e('SettingsAppLanguageController::changeLanguage()', e, s);
      return;
    }
    if (!mounted) return;
    LocalizationService.changeLocale(context, selectedLocale.languageCode);
  }

  @override
  Widget build(BuildContext context) {
    return SettingsAppLanguageView(controller: this);
  }
}
