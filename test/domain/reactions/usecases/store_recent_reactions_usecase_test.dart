import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:twake_chat/data/local/reaction/reaction_cache_manager.dart';
import 'package:twake_chat/data/repository/reactions/reactions_repository.provider.dart';
import 'package:twake_chat/domain/reactions/exceptions/recent_reactions_exception.dart';
import 'package:twake_chat/domain/reactions/usecases/store_recent_reactions_usecase.dart';
import 'package:twake_chat/domain/reactions/usecases/store_recent_reactions_usecase.provider.dart';
import 'package:twake_chat/domain/repository/reactions/reactions_repository.dart';

import 'store_recent_reactions_usecase_test.mocks.dart';

@GenerateNiceMocks([MockSpec<ReactionsRepository>()])
void main() {
  ProviderContainer createContainer({List<Override> overrides = const []}) =>
      ProviderContainer.test(retry: (_, _) => null, overrides: overrides);

  Future<List<String>?> storedReactions() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(ReactionsCacheManager.keyRecentReactions);
  }

  group('execute', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('execute_withSeveralEmojis_storesMostRecentFirst', () async {
      // Arrange
      final container = createContainer();
      final useCase = container.read(storeRecentReactionsUseCaseProvider);

      // Act
      await useCase.execute(emojiId: 'smile');
      await useCase.execute(emojiId: 'heart');
      await useCase.execute(emojiId: 'smile');

      // Assert
      expect(await storedReactions(), ['smile', 'heart']);
    });

    test('execute_withEmptyId_storesNothing', () async {
      // Arrange
      final container = createContainer();

      // Act
      await container
          .read(storeRecentReactionsUseCaseProvider)
          .execute(emojiId: '');

      // Assert
      expect(await storedReactions(), isNull);
    });

    test(
      'execute_whenReadFails_throwsStoreRecentReactionsExceptionAndStoresNothing',
      () async {
        // Arrange
        final repository = MockReactionsRepository();
        when(repository.getRecentReactions()).thenThrow(StateError('io'));
        final container = createContainer(
          overrides: [
            reactionsRepositoryProvider.overrideWithValue(repository),
          ],
        );

        // Act
        final result = container
            .read(storeRecentReactionsUseCaseProvider)
            .execute(emojiId: 'smile');

        // Assert
        await expectLater(
          result,
          throwsA(isA<StoreRecentReactionsException>()),
        );
        verifyNever(repository.storeRecentReactions(any));
      },
    );

    test(
      'execute_whenWriteFails_throwsStoreRecentReactionsException',
      () async {
        // Arrange
        final repository = MockReactionsRepository();
        when(repository.getRecentReactions()).thenAnswer((_) async => []);
        when(repository.storeRecentReactions(any)).thenThrow(StateError('io'));
        final container = createContainer(
          overrides: [
            reactionsRepositoryProvider.overrideWithValue(repository),
          ],
        );

        // Act
        final result = container
            .read(storeRecentReactionsUseCaseProvider)
            .execute(emojiId: 'smile');

        // Assert
        await expectLater(
          result,
          throwsA(isA<StoreRecentReactionsException>()),
        );
      },
    );
  });

  group('combine', () {
    test('combine_withNewEmoji_putsItFirst', () {
      // Act
      final result = StoreRecentReactionsUseCase.combine([
        'a',
        'b',
      ], emojiId: 'c');

      // Assert
      expect(result, ['c', 'a', 'b']);
    });

    test('combine_withExistingEmoji_movesItFirst', () {
      // Act
      final result = StoreRecentReactionsUseCase.combine([
        'a',
        'b',
        'c',
      ], emojiId: 'b');

      // Assert
      expect(result, ['b', 'a', 'c']);
    });

    test('combine_withEmptyList_returnsOnlyTheEmoji', () {
      // Act
      final result = StoreRecentReactionsUseCase.combine([], emojiId: 'a');

      // Assert
      expect(result, ['a']);
    });

    test('combine_withEmojiAlreadyFirst_keepsTheList', () {
      // Arrange
      final reactions = List.generate(12, (i) => '$i');

      // Act
      final result = StoreRecentReactionsUseCase.combine(
        reactions,
        emojiId: '0',
      );

      // Assert
      expect(result, reactions);
    });

    test('combine_pastTheMaximum_dropsTheOldest', () {
      // Arrange
      final emojis = List.generate(20, (i) => '$i');
      var reactions = <String>[];

      // Act
      for (final emoji in emojis) {
        reactions = StoreRecentReactionsUseCase.combine(
          reactions,
          emojiId: emoji,
        );
      }

      // Assert
      expect(reactions, emojis.reversed.take(12).toList());
      expect(reactions.length, StoreRecentReactionsUseCase.maxRecentReactions);
    });
  });
}
