import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/encryption.dart';
import 'package:matrix/matrix.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:twake_chat/app_state/failure.dart';
import 'package:twake_chat/app_state/success.dart';
import 'package:twake_chat/domain/app_state/recovery_words/delete_recovery_states.dart';
import 'package:twake_chat/domain/app_state/recovery_words/save_recovery_words_failed.dart';
import 'package:twake_chat/domain/app_state/recovery_words/save_recovery_words_success.dart';
import 'package:twake_chat/domain/keychain_sharing/tom_encryption_reset_service.dart';
import 'package:twake_chat/domain/model/recovery_words/recovery_words.dart';
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
  late MockClient client;
  late MockBootstrap bootstrap;
  late MockGetRecoveryWordsUseCase getRecoveryWords;
  late MockSaveRecoveryWordsInteractor saveRecoveryWords;
  late TomEncryptionResetService service;

  setUpAll(() {
    provideDummy<Either<Failure, Success>>(
      const Right(DeleteRecoveryWordsSuccess()),
    );
    provideDummy<Either<SaveRecoveryWordsFailed, SaveRecoveryWordsSuccess>>(
      const Right(SaveRecoveryWordsSuccess()),
    );
  });

  setUp(() {
    client = MockClient();
    bootstrap = MockBootstrap();
    getRecoveryWords = MockGetRecoveryWordsUseCase();
    saveRecoveryWords = MockSaveRecoveryWordsInteractor();
    final deleteRecoveryWords = MockDeleteRecoveryWordsInteractor();
    final encryption = MockEncryption();
    final newSsssKey = MockOpenSSSS();
    var bootstrapState = BootstrapState.askNewSsss;
    when(
      deleteRecoveryWords.execute(),
    ).thenAnswer((_) async => const Right(DeleteRecoveryWordsSuccess()));
    when(
      saveRecoveryWords.execute(any),
    ).thenAnswer((_) async => const Right(SaveRecoveryWordsSuccess()));
    when(client.encryption).thenReturn(encryption);
    when(encryption.bootstrap()).thenReturn(bootstrap);
    when(bootstrap.state).thenAnswer((_) => bootstrapState);
    when(bootstrap.newSsss()).thenAnswer((_) async {
      bootstrapState = BootstrapState.done;
    });
    when(bootstrap.newSsssKey).thenReturn(newSsssKey);
    when(newSsssKey.recoveryKey).thenReturn('new-key');
    service = TomEncryptionResetService(
      client: client,
      getRecoveryWordsUseCase: getRecoveryWords,
      deleteRecoveryWordsInteractor: deleteRecoveryWords,
      saveRecoveryWordsInteractor: saveRecoveryWords,
    );
  });

  test('reset_whenFetchingOldWordsFails_uploadsTheNewKeyAndSucceeds', () async {
    // Arrange
    when(
      getRecoveryWords.execute(),
    ).thenThrow(GetRecoveryWordsException(StateError('no host')));

    // Act
    final result = await service.reset();

    // Assert
    expect(result, TomEncryptionResetResult.success);
    verify(saveRecoveryWords.execute('new-key')).called(1);
  });

  test('reset_whenVaultAlreadyHoldsTheNewKey_doesNotUploadIt', () async {
    // Arrange
    when(
      getRecoveryWords.execute(),
    ).thenAnswer((_) async => RecoveryWords('new-key'));

    // Act
    final result = await service.reset();

    // Assert
    expect(result, TomEncryptionResetResult.success);
    verifyNever(saveRecoveryWords.execute(any));
  });
}
