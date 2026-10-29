import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:twake_chat/data/local/reaction/reaction_cache_manager.dart';
import 'package:twake_chat/data/repository/reactions/reactions_repository.provider.dart';
import 'package:twake_chat/domain/reactions/exceptions/recent_reactions_exception.dart';
import 'package:twake_chat/domain/reactions/usecases/get_recent_reactions_usecase.provider.dart';
import 'package:twake_chat/domain/repository/reactions/reactions_repository.dart';

import 'get_recent_reactions_usecase_test.mocks.dart';

@GenerateNiceMocks([MockSpec<ReactionsRepository>()])
void main() {
  ProviderContainer createContainer({List<Override> overrides = const []}) =>
      ProviderContainer.test(retry: (_, _) => null, overrides: overrides);

  test('execute_whenNothingStored_returnsEmptyList', () async {
    // Arrange
    SharedPreferences.setMockInitialValues({});
    final container = createContainer();

    // Act
    final result = await container
        .read(getRecentReactionsUseCaseProvider)
        .execute();

    // Assert
    expect(result, isEmpty);
  });

  test('execute_withStoredReactions_returnsThemInOrder', () async {
    // Arrange
    SharedPreferences.setMockInitialValues({
      ReactionsCacheManager.keyRecentReactions: ['smile', 'heart'],
    });
    final container = createContainer();

    // Act
    final result = await container
        .read(getRecentReactionsUseCaseProvider)
        .execute();

    // Assert
    expect(result, ['smile', 'heart']);
  });

  test(
    'execute_whenRepositoryFails_throwsGetRecentReactionsException',
    () async {
      // Arrange
      final repository = MockReactionsRepository();
      when(repository.getRecentReactions()).thenThrow(StateError('io'));
      final container = createContainer(
        overrides: [reactionsRepositoryProvider.overrideWithValue(repository)],
      );

      // Act
      final result = container
          .read(getRecentReactionsUseCaseProvider)
          .execute();

      // Assert
      await expectLater(result, throwsA(isA<GetRecentReactionsException>()));
    },
  );
}
