import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter/widgets.dart';

extension LocaleExtension on Locale {
  String getLanguageNameByCurrentLocale(BuildContext context) {
    switch (languageCode) {
      case 'fr':
        return L10n.of(context)!.languageFrench;
      case 'en':
        return L10n.of(context)!.languageEnglish;
      case 'vi':
        return L10n.of(context)!.languageVietnamese;
      case 'ru':
        return L10n.of(context)!.languageRussian;
      case 'ar':
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
