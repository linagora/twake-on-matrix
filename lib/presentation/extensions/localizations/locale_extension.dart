import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localized_locales/flutter_localized_locales.dart';

extension LocaleExtension on Locale {
  String getLanguageNameByCurrentLocale(BuildContext context) {
    switch (languageCode) {
      case 'fr':
        return LocaleNames.of(context)!.nameOf('fr') ??
            L10n.of(context)!.languageFrench;
      case 'en':
        return LocaleNames.of(context)!.nameOf('en') ??
            L10n.of(context)!.languageEnglish;
      case 'vi':
        return LocaleNames.of(context)!.nameOf('vi') ??
            L10n.of(context)!.languageVietnamese;
      case 'ru':
        return LocaleNames.of(context)!.nameOf('ru') ??
            L10n.of(context)!.languageRussian;
      default:
        return '';
    }
  }

  String getSourceLanguageName() {
    switch (languageCode) {
      case 'fr':
        return 'Français';
      case 'en':
        return 'English';
      case 'vi':
        return 'Tiếng Việt';
      case 'ru':
        return 'Русский';
      default:
        return '';
    }
  }
}
