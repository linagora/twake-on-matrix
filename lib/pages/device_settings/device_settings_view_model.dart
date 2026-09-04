import 'package:collection/collection.dart';
import 'package:twake_chat/domain/app_state/device_settings/get_devices_state.dart';
import 'package:twake_chat/pages/device_settings/device_settings_state.dart';
import 'package:twake_chat/pages/device_settings/providers/device_settings_providers.dart';
import 'package:matrix/matrix.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'device_settings_view_model.g.dart';

@riverpod
class DevicesSettingsViewModel extends _$DevicesSettingsViewModel {
  Future<void>? _loadInFlight;

  @override
  DevicesSettingsState build() {
    return const DevicesSettingsState.initial();
  }

  bool _isOwnDevice(Device userDevice, Client client) =>
      userDevice.deviceId == client.deviceID;

  List<Device>? get _devices => switch (state) {
    DevicesSettingsLoaded(:final devices) => devices,
    DevicesSettingsDeletingDevices(:final devices) => devices,
    DevicesSettingsDeleteDevicesError(:final devices) => devices,
    _ => null,
  };

  VerificationBannerVisibility get _bannerVisibility => switch (state) {
    DevicesSettingsLoaded(:final bannerVisibility) => bannerVisibility,
    DevicesSettingsDeletingDevices(:final bannerVisibility) => bannerVisibility,
    DevicesSettingsDeleteDevicesError(:final bannerVisibility) =>
      bannerVisibility,
    _ => VerificationBannerVisibility.shown,
  };

  int get _keysRevision => switch (state) {
    DevicesSettingsLoaded(:final keysRevision) => keysRevision,
    DevicesSettingsDeletingDevices(:final keysRevision) => keysRevision,
    DevicesSettingsDeleteDevicesError(:final keysRevision) => keysRevision,
    _ => 0,
  };

  /// Transitions to a new "devices loaded" variant, carrying over the
  /// current [_devices]/[_bannerVisibility]/[_keysRevision] unless
  /// overridden. No-op if devices haven't loaded yet.
  void _transition({
    List<Device>? devices,
    VerificationBannerVisibility? bannerVisibility,
    int? keysRevision,
    String? deleteError,
    bool deleting = false,
  }) {
    final resolvedDevices = devices ?? _devices;
    if (resolvedDevices == null) return;
    final resolvedBannerVisibility = bannerVisibility ?? _bannerVisibility;
    final resolvedKeysRevision = keysRevision ?? _keysRevision;
    if (deleting) {
      state = DevicesSettingsState.deletingDevices(
        devices: resolvedDevices,
        bannerVisibility: resolvedBannerVisibility,
        keysRevision: resolvedKeysRevision,
      );
    } else if (deleteError != null) {
      state = DevicesSettingsState.deleteDevicesError(
        devices: resolvedDevices,
        message: deleteError,
        bannerVisibility: resolvedBannerVisibility,
        keysRevision: resolvedKeysRevision,
      );
    } else {
      state = DevicesSettingsState.loaded(
        devices: resolvedDevices,
        bannerVisibility: resolvedBannerVisibility,
        keysRevision: resolvedKeysRevision,
      );
    }
  }

  Device? thisDevice(Client client) =>
      _devices?.firstWhereOrNull((d) => _isOwnDevice(d, client));

  List<Device> notThisDevice(Client client) => List<Device>.from(_devices ?? [])
    ..removeWhere((d) => _isOwnDevice(d, client))
    ..sort((a, b) => (b.lastSeenTs ?? 0).compareTo(a.lastSeenTs ?? 0));

  bool showVerificationBanner(Client client) {
    final devices = _devices;
    if (devices == null) return false;
    if (_bannerVisibility == VerificationBannerVisibility.dismissed) {
      return false;
    }
    if (devices.isEmpty) return false;
    final deviceKeys = client.userDeviceKeys[client.userID]?.deviceKeys;
    // Devices settings banner: any session in the `/devices` list that will
    // not receive room keys (`encryptToDevice == false`), including this
    // session when it is out of sync.
    //
    // Intentionally different from the chat banner, which warns about
    // *other* unverified sessions via [DeviceKeys.verified].
    return devices.any(
      (device) => deviceKeys?[device.deviceId]?.encryptToDevice == false,
    );
  }

  void dismissVerificationBanner() {
    _transition(bannerVisibility: VerificationBannerVisibility.dismissed);
  }

  Future<void> loadUserDevices(Client client) {
    if (_devices != null) return Future.value();
    return _loadInFlight ??= _loadUserDevices(client).whenComplete(() {
      _loadInFlight = null;
    });
  }

  Future<void> _loadUserDevices(Client client) async {
    await ref
        .read(getDevicesInteractorProvider)
        .execute(client: client)
        .forEach((either) {
          either.fold(
            (failure) {
              if (failure is GetDevicesEmpty) {
                state = const DevicesSettingsState.loaded(devices: []);
              } else if (failure is GetDevicesFailed) {
                state = DevicesSettingsState.error(
                  exception: failure.exception,
                );
              }
            },
            (success) {
              if (success is GetDevicesSuccess) {
                state = DevicesSettingsState.loaded(devices: success.devices);
              }
            },
          );
        });
  }

  Future<void> reload(Client client) {
    state = const DevicesSettingsState.initial();
    return _loadInFlight ??= _loadUserDevices(client).whenComplete(() {
      _loadInFlight = null;
    });
  }

  void setLoadingDeletingDevices(bool loading) =>
      _transition(deleting: loading);

  void setErrorDeletingDevices(String? error) =>
      _transition(deleteError: error);

  void refreshDeviceKeys() {
    if (_devices == null) return;
    // Device list identity is unchanged after SAS; bump keysRevision so
    // Freezed equality fails and list items re-read DeviceKeys.verified.
    _transition(keysRevision: _keysRevision + 1);
  }
}
