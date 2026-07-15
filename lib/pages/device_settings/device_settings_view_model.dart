import 'package:collection/collection.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/domain/app_state/device_settings/get_devices_state.dart';
import 'package:fluffychat/domain/usecase/device_settings/get_devices_interactor.dart';
import 'package:fluffychat/pages/device_settings/device_settings_state.dart';
import 'package:matrix/matrix.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'device_settings_view_model.g.dart';

@riverpod
class DevicesSettingsViewModel extends _$DevicesSettingsViewModel {
  final GetDevicesInteractor _getDevicesInteractor = getIt
      .get<GetDevicesInteractor>();

  @override
  DevicesSettingsState build() {
    return const DevicesSettingsState();
  }

  bool _isOwnDevice(Device userDevice, Client client) =>
      userDevice.deviceId == client.deviceID;

  Device? thisDevice(Client client) =>
      state.devices?.firstWhereOrNull((d) => _isOwnDevice(d, client));

  List<Device> notThisDevice(Client client) =>
      List<Device>.from(state.devices ?? [])
        ..removeWhere((d) => _isOwnDevice(d, client))
        ..sort((a, b) => (b.lastSeenTs ?? 0).compareTo(a.lastSeenTs ?? 0));

  bool showVerificationBanner(Client client) {
    if (state.verificationBannerDismissed) return false;
    final devices = state.devices;
    if (devices == null || devices.isEmpty) return false;
    final deviceKeys = client.userDeviceKeys[client.userID]?.deviceKeys;
    // encryptToDevice reflects whether this device will actually receive
    // room keys and be able to decrypt messages (per ShareKeysWith policy),
    // unlike directVerified/verified which the SDK force-trusts for the
    // own device regardless of any user action.
    return devices.any(
      (device) => deviceKeys?[device.deviceId]?.encryptToDevice == false,
    );
  }

  Future<void> loadUserDevices(Client client) async {
    if (state.devices != null) return;
    await _getDevicesInteractor
        .execute(client: client)
        .forEach((either) {
          either.fold((failure) {}, (success) {
            if (success is GetDevicesSuccess) {
              state = state.copyWith(devices: success.devices);
            }
          });
        });
  }

  void reload() => state = state.copyWith(clearDevices: true);

  void setLoadingDeletingDevices(bool loading) {
    state = state.copyWith(loadingDeletingDevices: loading);
  }

  void setErrorDeletingDevices(String? error) {
    state = state.copyWith(
      errorDeletingDevices: error,
      clearErrorDeletingDevices: error == null,
    );
  }

  void refreshDeviceKeys() {
    state = state.copyWith(devices: List<Device>.from(state.devices ?? []));
  }
}
