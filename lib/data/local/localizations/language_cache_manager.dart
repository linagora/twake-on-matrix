import 'dart:ui';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/utils/famedlysdk_store.dart';
import 'package:matrix/matrix.dart';

class LanguageCacheManager {
  static const keyLanguageCode = 'LANGUAGE_CODE';
  static const keyCountryCode = 'COUNTRY_CODE';

  final Store pres = getIt.get<Store>();

  Future<void> persistLanguage(Locale localeCurrent) async {
    await Future.wait([
      pres.setItem(keyLanguageCode, localeCurrent.languageCode),
      pres.setItem(keyCountryCode, localeCurrent.countryCode ?? ''),
    ]);
  }

  Future<Locale?> getStoredLanguage() async {
    String? languageCode;
    String? countryCode;

    languageCode = await pres.getItem(keyLanguageCode);
    countryCode = await pres.getItem(keyCountryCode);
    Logs().d(
      'LanguageCacheManager::getStoredLanguage(): languageCode: $languageCode',
    );
    if (languageCode?.isNotEmpty == true) {
      return Locale(languageCode!, countryCode);
    }
    return null;
  }

  Future<void> removeLanguage() async {
    return Future.sync(() async {
      await Future.wait(
        [pres.deleteItem(keyLanguageCode), pres.deleteItem(keyCountryCode)],
      );
    }).catchError((error) {
      Logs().e('LanguageCacheManager::removeLanguage(): error: $error');
      return null;
    });
  }
}
