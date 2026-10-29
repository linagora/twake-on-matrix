import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:twake_chat/data/repository/recovery_words_repository.provider.dart';
import 'package:twake_chat/domain/model/recovery_words/recovery_words.dart';
import 'package:twake_chat/domain/recovery/exceptions/recovery_words_exception.dart';
import 'package:twake_chat/domain/recovery/usecases/get_recovery_words_usecase.provider.dart';
import 'package:twake_chat/domain/repository/recovery_words_repository.dart';

import 'get_recovery_words_usecase_test.mocks.dart';

@GenerateNiceMocks([MockSpec<RecoveryWordsRepository>()])
void main() {
  late MockRecoveryWordsRepository repository;

  ProviderContainer createContainer() => ProviderContainer.test(
    retry: (_, _) => null,
    overrides: <Override>[
      recoveryWordsRepositoryProvider.overrideWithValue(repository),
    ],
  );

  setUp(() => repository = MockRecoveryWordsRepository());

  test('execute_whenRepositoryReturnsWords_returnsThem', () async {
    // Arrange
    when(
      repository.getRecoveryWords(),
    ).thenAnswer((_) async => RecoveryWords('alpha beta'));
    final container = createContainer();

    // Act
    final result = await container
        .read(getRecoveryWordsUseCaseProvider)
        .execute();

    // Assert
    expect(result, RecoveryWords('alpha beta'));
  });

  test(
    'execute_whenRepositoryThrows_throwsGetRecoveryWordsException',
    () async {
      // Arrange
      final error = StateError('network');
      when(repository.getRecoveryWords()).thenThrow(error);
      final container = createContainer();

      // Act
      final result = container.read(getRecoveryWordsUseCaseProvider).execute();

      // Assert
      await expectLater(
        result,
        throwsA(
          isA<GetRecoveryWordsException>().having(
            (e) => e.cause,
            'cause',
            error,
          ),
        ),
      );
    },
  );
}
