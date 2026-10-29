import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/encryption.dart';
import 'package:matrix/matrix.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:twake_chat/di/global/get_it_initializer.dart';
import 'package:twake_chat/app_state/failure.dart';
import 'package:twake_chat/app_state/success.dart';
import 'package:twake_chat/domain/app_state/recovery_words/delete_recovery_states.dart';
import 'package:twake_chat/domain/app_state/recovery_words/save_recovery_words_failed.dart';
import 'package:twake_chat/domain/app_state/recovery_words/save_recovery_words_success.dart';
import 'package:twake_chat/domain/keychain_sharing/tom_encryption_reset_service.dart';
import 'package:twake_chat/domain/recovery/exceptions/recovery_words_exception.dart';
import 'package:twake_chat/domain/recovery/usecases/get_recovery_words_usecase.dart';
import 'package:twake_chat/domain/usecase/recovery/delete_recovery_words_interactor.dart';
import 'package:twake_chat/domain/usecase/recovery/save_recovery_words_interactor.dart';

import 'tom_encryption_reset_service_test.mocks.dart';

@GenerateNiceMocks([
  MockSpec<Bootstrap>(),
  MockSpec<Client>(),
  MockSpec<DeleteRecoveryWordsInteractor>(),
  MockSpec<Encryption>(),
  MockSpec<GetRecoveryWordsUseCase>(),
  MockSpec<OpenSSSS>(),
  MockSpec<SaveRecoveryWordsInteractor>(),
])
void main() {
  late MockSaveRecoveryWordsInteractor saveRecoveryWords;

  setUpAll(() {
    provideDummy<Either<Failure, Success>>(
      const Right(DeleteRecoveryWordsSuccess()),
    );
    provideDummy<Either<SaveRecoveryWordsFailed, SaveRecoveryWordsSuccess>>(
      const Right(SaveRecoveryWordsSuccess()),
    );
  });

  setUp(() {
    final deleteRecoveryWords = MockDeleteRecoveryWordsInteractor();
    saveRecoveryWords = MockSaveRecoveryWordsInteractor();
    when(
      deleteRecoveryWords.execute(),
    ).thenAnswer((_) async => const Right(DeleteRecoveryWordsSuccess()));
    when(
      saveRecoveryWords.execute(any),
    ).thenAnswer((_) async => const Right(SaveRecoveryWordsSuccess()));
    getIt.registerSingleton<DeleteRecoveryWordsInteractor>(deleteRecoveryWords);
    getIt.registerSingleton<SaveRecoveryWordsInteractor>(saveRecoveryWords);
  });

  tearDown(() => getIt.reset());

  test('reset_whenFetchingOldWordsFails_uploadsTheNewKeyAndSucceeds', () async {
    // Arrange
    final client = MockClient();
    final encryption = MockEncryption();
    final bootstrap = MockBootstrap();
    final newSsssKey = MockOpenSSSS();
    final getRecoveryWords = MockGetRecoveryWordsUseCase();
    var bootstrapState = BootstrapState.askNewSsss;
    when(client.encryption).thenReturn(encryption);
    when(encryption.bootstrap()).thenReturn(bootstrap);
    when(bootstrap.state).thenAnswer((_) => bootstrapState);
    when(bootstrap.newSsss()).thenAnswer((_) async {
      bootstrapState = BootstrapState.done;
    });
    when(bootstrap.newSsssKey).thenReturn(newSsssKey);
    when(newSsssKey.recoveryKey).thenReturn('new-key');
    when(
      getRecoveryWords.execute(),
    ).thenThrow(GetRecoveryWordsException(StateError('no host')));
    final service = TomEncryptionResetService(
      client: client,
      getRecoveryWordsUseCase: getRecoveryWords,
    );

    // Act
    final result = await service.reset();

    // Assert
    expect(result, TomEncryptionResetResult.success);
    verify(saveRecoveryWords.execute('new-key')).called(1);
  });
}
