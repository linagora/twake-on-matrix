import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/data/repository/drive/drive_repository.provider.dart';
import 'package:twake_chat/domain/usecase/drive/drive_interactor.provider.dart';

import 'fake_drive_session_repository.dart';

Future<void> _buildsTheBridgeInteractorFromTheRepository() async {
  final container = ProviderContainer(
    overrides: [
      driveSessionRepositoryProvider.overrideWithValue(
        FakeDriveSessionRepository(),
      ),
    ],
  );
  addTearDown(container.dispose);

  final intent = await container
      .read(createDrivePickerSessionViaBridgeInteractorProvider)
      .execute(fakeDrivePickerConfig);

  expect(intent, fakeDrivePickerSession);
}

void main() {
  test(
    'builds the bridge interactor from the repository',
    _buildsTheBridgeInteractorFromTheRepository,
  );
}
