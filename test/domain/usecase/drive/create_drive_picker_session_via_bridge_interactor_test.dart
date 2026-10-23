import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/domain/model/drive/drive_exceptions.dart';
import 'package:twake_chat/domain/usecase/drive/create_drive_picker_session_via_bridge_interactor.dart';

import 'fake_drive_session_repository.dart';

Future<void> _returnsTheIntentWhenBridgeIsAvailable() async {
  final repository = FakeDriveSessionRepository();

  final intent = await CreateDrivePickerSessionViaBridgeInteractor(
    repository,
  ).execute(fakeDrivePickerConfig);

  expect(intent, fakeDrivePickerSession);
  expect(repository.bridgeCalls, 1);
}

Future<void> _throwsUnavailableWithoutCallingTheRepository() async {
  final repository = FakeDriveSessionRepository(isBridgeAvailable: false);

  await expectLater(
    CreateDrivePickerSessionViaBridgeInteractor(
      repository,
    ).execute(fakeDrivePickerConfig),
    throwsA(isA<DriveBridgeUnavailableException>()),
  );
  expect(repository.bridgeCalls, 0);
}

Future<void> _letsRepositoryFailuresThrough() async {
  final repository = FakeDriveSessionRepository(error: StateError('boom'));

  await expectLater(
    CreateDrivePickerSessionViaBridgeInteractor(
      repository,
    ).execute(fakeDrivePickerConfig),
    throwsStateError,
  );
}

void main() {
  test(
    'returns the intent when the bridge is available',
    _returnsTheIntentWhenBridgeIsAvailable,
  );
  test(
    'throws unavailable without calling the repository',
    _throwsUnavailableWithoutCallingTheRepository,
  );
  test('lets repository failures through', _letsRepositoryFailuresThrough);
}
