import 'package:dartz/dartz.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/encryption.dart';
import 'package:matrix/encryption/cross_signing.dart';
import 'package:matrix/matrix.dart';
// ignore: implementation_imports
import 'package:matrix/src/utils/cached_stream_controller.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:twake_chat/domain/app_state/recovery/unlock_ssss_state.dart';
import 'package:twake_chat/app_state/failure.dart';
import 'package:twake_chat/app_state/success.dart';
import 'package:twake_chat/domain/app_state/recovery_words/delete_recovery_states.dart';
import 'package:twake_chat/domain/model/recovery_words/recovery_words.dart';
import 'package:twake_chat/domain/recovery/exceptions/recovery_words_exception.dart';
import 'package:twake_chat/domain/recovery/usecases/get_recovery_words_usecase.dart';
import 'package:twake_chat/domain/recovery/usecases/get_recovery_words_usecase.provider.dart';
import 'package:twake_chat/domain/usecase/recovery/delete_recovery_words_interactor.dart';
import 'package:twake_chat/domain/usecase/recovery/save_recovery_words_interactor.dart';
import 'package:twake_chat/domain/usecase/recovery/unlock_ssss_with_recovery_key_interactor.dart';
import 'package:twake_chat/pages/bootstrap/bootstrap_providers.dart';
import 'package:twake_chat/pages/bootstrap/tom_bootstrap_controller.dart';
import 'package:twake_chat/pages/bootstrap/tom_bootstrap_state.dart';

import 'tom_bootstrap_controller_test.mocks.dart';

@GenerateNiceMocks([
  MockSpec<Bootstrap>(),
  MockSpec<Client>(),
  MockSpec<CrossSigning>(),
  MockSpec<DeleteRecoveryWordsInteractor>(),
  MockSpec<Encryption>(),
  MockSpec<GetRecoveryWordsUseCase>(),
  MockSpec<KeyManager>(),
  MockSpec<SaveRecoveryWordsInteractor>(),
  MockSpec<UnlockSsssWithRecoveryKeyInteractor>(),
])
void main() {
  late MockClient client;
  late MockDeleteRecoveryWordsInteractor deleteRecoveryWords;
  late MockGetRecoveryWordsUseCase getRecoveryWords;
  late MockUnlockSsssWithRecoveryKeyInteractor unlockSsss;

  setUpAll(() {
    provideDummy<UnlockSsssState>(const UnlockSsssState.success());
    provideDummy<Either<Failure, Success>>(
      const Right(DeleteRecoveryWordsSuccess()),
    );
  });

  setUp(() {
    client = MockClient();
    deleteRecoveryWords = MockDeleteRecoveryWordsInteractor();
    getRecoveryWords = MockGetRecoveryWordsUseCase();
    unlockSsss = MockUnlockSsssWithRecoveryKeyInteractor();
  });

  ProviderContainer createContainer() => ProviderContainer.test(
    retry: (_, _) => null,
    overrides: <Override>[
      deleteRecoveryWordsInteractorProvider.overrideWithValue(
        deleteRecoveryWords,
      ),
      getRecoveryWordsUseCaseProvider.overrideWithValue(getRecoveryWords),
      saveRecoveryWordsInteractorProvider.overrideWithValue(
        MockSaveRecoveryWordsInteractor(),
      ),
      unlockSsssWithRecoveryKeyInteractorProvider.overrideWithValue(unlockSsss),
    ],
  );

  TomBootstrapControllerProvider controllerProvider({
    required bool wipeRecovery,
    bool twakeSupported = true,
  }) => tomBootstrapControllerProvider(
    client,
    wipe: false,
    wipeRecovery: wipeRecovery,
    twakeSupported: twakeSupported,
  );

  Future<TomBootstrapState> runController({
    required bool wipeRecovery,
    bool twakeSupported = true,
    Future<void> Function()? afterBuild,
  }) async {
    final container = createContainer();
    final provider = controllerProvider(
      wipeRecovery: wipeRecovery,
      twakeSupported: twakeSupported,
    );
    container.listen(provider, (_, _) {});
    await pumpEventQueue();
    await afterBuild?.call();
    await pumpEventQueue();
    return container.read(provider);
  }

  group('with key backup enabled and keys not cached', () {
    late MockBootstrap bootstrap;
    late CachedStreamController<SyncUpdate> onSync;

    setUp(() {
      final encryption = MockEncryption();
      final keyManager = MockKeyManager();
      final crossSigning = MockCrossSigning();
      bootstrap = MockBootstrap();
      onSync = CachedStreamController<SyncUpdate>();
      when(client.onSync).thenReturn(onSync);
      when(client.encryption).thenReturn(encryption);
      when(encryption.keyManager).thenReturn(keyManager);
      when(encryption.crossSigning).thenReturn(crossSigning);
      when(keyManager.enabled).thenReturn(true);
      when(keyManager.isCached()).thenAnswer((_) async => false);
      when(crossSigning.isCached()).thenAnswer((_) async => true);
      when(
        encryption.bootstrap(onUpdate: anyNamed('onUpdate')),
      ).thenReturn(bootstrap);
    });

    test('build_whenFetchingRecoveryWordsFails_emitsNoRecoveryWords', () async {
      // Arrange
      when(
        getRecoveryWords.execute(),
      ).thenThrow(GetRecoveryWordsException(StateError('no host')));

      // Act
      final state = await runController(
        wipeRecovery: false,
        afterBuild: () async => onSync.add(SyncUpdate(nextBatch: 'batch')),
      );

      // Assert
      expect(state, isA<TomBootstrapNoRecoveryWordsState>());
      verifyNever(
        unlockSsss.execute(
          bootstrap: anyNamed('bootstrap'),
          recoveryKey: anyNamed('recoveryKey'),
        ),
      );
    });

    test(
      'build_whenFetchingRecoveryWordsFails_popsFalseAfterTheCloseDelay',
      () {
        fakeAsync((async) {
          // Arrange
          when(
            getRecoveryWords.execute(),
          ).thenThrow(GetRecoveryWordsException(StateError('no host')));
          final container = createContainer();
          final provider = controllerProvider(wipeRecovery: false);
          container.listen(provider, (_, _) {});
          async.flushMicrotasks();
          onSync.add(SyncUpdate(nextBatch: 'batch'));
          async.flushMicrotasks();
          expect(container.read(provider).popValue, isNull);

          // Act
          async.elapse(TomBootstrapController.noRecoveryWordsCloseDelay);

          // Assert
          expect(container.read(provider).popValue, isFalse);
        });
      },
    );

    test('build_whenRecoveryWordsFetched_unlocksSsssWithThem', () async {
      // Arrange
      var bootstrapState = BootstrapState.openExistingSsss;
      when(bootstrap.state).thenAnswer((_) => bootstrapState);
      when(
        getRecoveryWords.execute(),
      ).thenAnswer((_) async => RecoveryWords('alpha beta'));
      when(
        unlockSsss.execute(
          bootstrap: anyNamed('bootstrap'),
          recoveryKey: anyNamed('recoveryKey'),
        ),
      ).thenAnswer((_) async {
        bootstrapState = BootstrapState.done;
        return const UnlockSsssState.success();
      });

      // Act
      final state = await runController(
        wipeRecovery: false,
        afterBuild: () async => onSync.add(SyncUpdate(nextBatch: 'batch')),
      );

      // Assert
      verify(
        unlockSsss.execute(bootstrap: bootstrap, recoveryKey: 'alpha beta'),
      ).called(1);
      expect(state, isA<TomBootstrapDoneState>());
    });
  });

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
