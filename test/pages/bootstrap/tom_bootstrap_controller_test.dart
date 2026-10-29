import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';
// ignore: implementation_imports
import 'package:matrix/src/utils/cached_stream_controller.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:twake_chat/domain/app_state/recovery_words/delete_recovery_states.dart';
import 'package:twake_chat/domain/recovery/exceptions/recovery_words_exception.dart';
import 'package:twake_chat/domain/recovery/usecases/get_recovery_words_usecase.dart';
import 'package:twake_chat/domain/recovery/usecases/get_recovery_words_usecase.provider.dart';
import 'package:twake_chat/domain/usecase/recovery/delete_recovery_words_interactor.dart';
import 'package:twake_chat/domain/usecase/recovery/save_recovery_words_interactor.dart';
import 'package:twake_chat/pages/bootstrap/bootstrap_providers.dart';
import 'package:twake_chat/pages/bootstrap/tom_bootstrap_controller.dart';
import 'package:twake_chat/pages/bootstrap/tom_bootstrap_state.dart';

import 'tom_bootstrap_controller_test.mocks.dart';

@GenerateNiceMocks([
  MockSpec<Client>(),
  MockSpec<DeleteRecoveryWordsInteractor>(),
  MockSpec<GetRecoveryWordsUseCase>(),
  MockSpec<SaveRecoveryWordsInteractor>(),
])
void main() {
  late MockClient client;
  late MockDeleteRecoveryWordsInteractor deleteRecoveryWords;
  late MockGetRecoveryWordsUseCase getRecoveryWords;

  setUp(() {
    client = MockClient();
    deleteRecoveryWords = MockDeleteRecoveryWordsInteractor();
    getRecoveryWords = MockGetRecoveryWordsUseCase();
  });

  Future<TomBootstrapState> runController({
    required bool wipeRecovery,
    bool twakeSupported = true,
    Future<void> Function()? afterBuild,
  }) async {
    final container = ProviderContainer.test(
      retry: (_, _) => null,
      overrides: <Override>[
        deleteRecoveryWordsInteractorProvider.overrideWithValue(
          deleteRecoveryWords,
        ),
        getRecoveryWordsUseCaseProvider.overrideWithValue(getRecoveryWords),
        saveRecoveryWordsInteractorProvider.overrideWithValue(
          MockSaveRecoveryWordsInteractor(),
        ),
      ],
    );
    final provider = tomBootstrapControllerProvider(
      client,
      wipe: false,
      wipeRecovery: wipeRecovery,
      twakeSupported: twakeSupported,
    );
    container.listen(provider, (_, _) {});
    await pumpEventQueue();
    await afterBuild?.call();
    await pumpEventQueue();
    return container.read(provider);
  }

  test(
    'build_whenFetchingRecoveryWordsFails_keepsCheckingWithoutWords',
    () async {
      // Arrange
      final onSync = CachedStreamController<SyncUpdate>();
      when(client.onSync).thenReturn(onSync);
      when(
        getRecoveryWords.execute(),
      ).thenThrow(GetRecoveryWordsException(StateError('no host')));

      // Act
      final state = await runController(
        wipeRecovery: false,
        afterBuild: () async => onSync.add(SyncUpdate(nextBatch: 'batch')),
      );

      // Assert
      expect(state, isA<TomBootstrapCheckingRecoveryState>());
      verify(getRecoveryWords.execute()).called(1);
    },
  );

  test('build_whenWipeFailsWithTwakeSupport_emitsWipeRecoveryFailed', () async {
    // Arrange
    when(
      deleteRecoveryWords.execute(),
    ).thenAnswer((_) async => const Left(DeleteRecoveryWordsFailed()));

    // Act
    final state = await runController(wipeRecovery: true);

    // Assert
    expect(state, isA<TomBootstrapWipeRecoveryFailedState>());
    verifyNever(getRecoveryWords.execute());
  });

  test(
    'build_whenWipeFailsWithoutTwakeSupport_emitsCheckingRecovery',
    () async {
      // Arrange
      when(
        deleteRecoveryWords.execute(),
      ).thenAnswer((_) async => const Left(DeleteRecoveryWordsFailed()));

      // Act
      final state = await runController(
        wipeRecovery: true,
        twakeSupported: false,
      );

      // Assert
      expect(state, isA<TomBootstrapCheckingRecoveryState>());
    },
  );
}
