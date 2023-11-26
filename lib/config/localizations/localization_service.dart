import 'package:collection/collection.dart';
import 'package:fluffychat/config/localizations/language_code_constants.dart';
import 'package:fluffychat/data/local/localizations/language_cache_manager.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';

class LocalizationService {
  static const defaultLocale = Locale(LanguageCodeConstants.english);
  static const fallbackLocale = Locale(LanguageCodeConstants.english);

  static ValueNotifier<Locale> currentLocale = ValueNotifier(defaultLocale);

  static const List<Locale> supportedLocales = <Locale>[
    Locale(LanguageCodeConstants.english),
    Locale(LanguageCodeConstants.vietnamese),
    Locale(LanguageCodeConstants.french),
    Locale(LanguageCodeConstants.russian),
  ];

  static void changeLocale(BuildContext context, String langCode) async {
    Logs().d('LocalizationService::changeLocale():langCode: $langCode');
    final newLocale =
        await getLocaleFromLanguage(langCode: langCode, context: context);
    Logs().d('LocalizationService::changeLocale():newLocale: $newLocale');
    currentLocale.value = newLocale;
    await WidgetsFlutterBinding.ensureInitialized().performReassemble();
  }

  static Future<Locale> getLocaleFromLanguage({
    required BuildContext context,
    String? langCode,
  }) async {
    final languageCacheManager = getIt.get<LanguageCacheManager>();
    Logs().d(
      'LocalizationService::_getLocaleFromLanguage:languageCacheManager: $languageCacheManager',
    );
    final localeStored = await languageCacheManager.getStoredLanguage();
    Logs().d(
      'LocalizationService::_getLocaleFromLanguage():localeStored: $localeStored',
    );
    if (localeStored != null) {
      return localeStored;
    } else {
      final languageCodeCurrent =
          langCode ?? View.of(context).platformDispatcher.locale.languageCode;
      Logs().d(
        'LocalizationService::_getLocaleFromLanguage():languageCodeCurrent: $languageCodeCurrent',
      );
      final localeSelected = supportedLocales.firstWhereOrNull(
        (locale) => locale.languageCode == languageCodeCurrent,
      );
      return localeSelected ?? View.of(context).platformDispatcher.locale;
    }
  }
}
