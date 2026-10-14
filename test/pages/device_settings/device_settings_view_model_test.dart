import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';

import 'package:twake_chat/app_state/failure.dart';
import 'package:twake_chat/app_state/success.dart';
import 'package:twake_chat/domain/app_state/device_settings/get_devices_state.dart';
import 'package:twake_chat/domain/usecase/device_settings/get_devices_interactor.dart';
import 'package:twake_chat/pages/device_settings/device_settings_state.dart';
import 'package:twake_chat/pages/device_settings/device_settings_view_model.dart';
import 'package:twake_chat/pages/device_settings/providers/device_settings_providers.dart';

import '../../fake_client.dart';

class FakeGetDevicesInteractor extends GetDevicesInteractor {
  final List<Stream<Either<Failure, Success>>> _results;
  var callCount = 0;

  FakeGetDevicesInteractor(this._results);

  @override
  Stream<Either<Failure, Success>> execute({required Client client}) {
    final result = _results[callCount.clamp(0, _results.length - 1)];
    callCount++;
    return result;
  }
}

Stream<Either<Failure, Success>> _success(List<Device> devices) =>
    Stream.value(Right(GetDevicesSuccess(devices: devices)));

Stream<Either<Failure, Success>> _failure() =>
    Stream.value(Left(GetDevicesFailed(exception: Exception('network error'))));

ProviderContainer _container(FakeGetDevicesInteractor interactor) {
  return ProviderContainer(
    overrides: [getDevicesInteractorProvider.overrideWithValue(interactor)],
  );
}

Future<void> _softReloadFailurePreservesLoadedDevices(_) async {
  final client = await getClient();
  final devices = [Device(deviceId: 'QBUAZIFURK', displayName: 'android')];
  final interactor = FakeGetDevicesInteractor([_success(devices), _failure()]);
  final container = _container(interactor);
  addTearDown(container.dispose);
  final notifier = container.read(devicesSettingsViewModelProvider.notifier);

  await notifier.loadUserDevices(client);
  expect(
    container.read(devicesSettingsViewModelProvider),
    isA<DevicesSettingsLoaded>(),
  );

  await notifier.renameDevice(
    client: client,
    deviceId: 'QBUAZIFURK',
    displayName: 'New name',
  );

  final state = container.read(devicesSettingsViewModelProvider);
  expect(
    state,
    isA<DevicesSettingsLoaded>(),
    reason:
        'a soft-reload failure after a successful rename must not blank the '
        'list into an error state',
  );
  expect(
    (state as DevicesSettingsLoaded).devices.single.displayName,
    'New name',
    reason:
        'a successful updateDevice must keep the new name even when the '
        'follow-up fetch fails',
  );
}

Future<void> _initialLoadFailureSetsErrorState(_) async {
  final client = await getClient();
  final interactor = FakeGetDevicesInteractor([_failure()]);
  final container = _container(interactor);
  addTearDown(container.dispose);
  final notifier = container.read(devicesSettingsViewModelProvider.notifier);

  await notifier.loadUserDevices(client);

  expect(
    container.read(devicesSettingsViewModelProvider),
    isA<DevicesSettingsError>(),
  );
}

void main() {
  test(
    'soft reload failure after renameDevice preserves the loaded devices '
    '(does not blank the list into an error state)',
    () => _softReloadFailurePreservesLoadedDevices(null),
  );

  test(
    'initial load failure still surfaces an error state',
    () => _initialLoadFailureSetsErrorState(null),
  );
}
