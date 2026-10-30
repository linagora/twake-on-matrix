import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/data/local/localizations/language_cache_manager.dart';
import 'package:twake_chat/data/local/localizations/language_cache_manager.provider.dart';
import 'package:twake_chat/data/repository/localizations/localizations_repository.provider.dart';
import 'package:twake_chat/domain/localizations/exceptions/save_language_exception.dart';
import 'package:twake_chat/domain/localizations/usecases/save_language_usecase.dart';
import 'package:twake_chat/domain/localizations/usecases/save_language_usecase.provider.dart';

import '../fake_localizations_repository.dart';

class _FakeLanguageCacheManager implements LanguageCacheManager {
  final List<Locale> persisted = [];

  @override
  Future<void> persistLanguage(Locale localeCurrent) async {
    persisted.add(localeCurrent);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  const locale = Locale('fr', 'FR');

  group('SaveLanguageUseCase', () {
    test('persists the locale through the repository', () async {
      final repository = FakeLocalizationsRepository();

      await SaveLanguageUseCase(repository).execute(locale);

      expect(repository.calls, [locale]);
    });

    test('wraps a repository error in SaveLanguageException', () async {
      final cause = Exception('storage');
      final repository = FakeLocalizationsRepository(
        onPersistLanguage: (_) async => throw cause,
      );

      await expectLater(
        SaveLanguageUseCase(repository).execute(locale),
        throwsA(
          isA<SaveLanguageException>().having((e) => e.cause, 'cause', cause),
        ),
      );
    });
  });

  group('saveLanguageUseCaseProvider', () {
    test('uses the overridden repository', () async {
      final repository = FakeLocalizationsRepository();
      final container = ProviderContainer.test(
        overrides: [
          localizationsRepositoryProvider.overrideWithValue(repository),
        ],
      );

      await container.read(saveLanguageUseCaseProvider).execute(locale);

      expect(repository.calls, [locale]);
    });

    test('persists the locale down to the language cache', () async {
      final cacheManager = _FakeLanguageCacheManager();
      final container = ProviderContainer.test(
        overrides: [
          languageCacheManagerProvider.overrideWithValue(cacheManager),
        ],
      );

      await container.read(saveLanguageUseCaseProvider).execute(locale);

      expect(cacheManager.persisted, [locale]);
    });
  });
}
