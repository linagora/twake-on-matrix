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

  Future<void>? _loadInFlight;

  @override
  DevicesSettingsState build() {
    return const DevicesSettingsInitial();
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

  /// Transitions to a new "devices loaded" variant, carrying over the
  /// current [_devices]/[_bannerVisibility] unless overridden. No-op if
  /// devices haven't loaded yet.
  void _transition({
    List<Device>? devices,
    VerificationBannerVisibility? bannerVisibility,
    String? deleteError,
    bool deleting = false,
  }) {
    final resolvedDevices = devices ?? _devices;
    if (resolvedDevices == null) return;
    final resolvedBannerVisibility = bannerVisibility ?? _bannerVisibility;
    if (deleting) {
      state = DevicesSettingsDeletingDevices(
        devices: resolvedDevices,
        bannerVisibility: resolvedBannerVisibility,
      );
    } else if (deleteError != null) {
      state = DevicesSettingsDeleteDevicesError(
        devices: resolvedDevices,
        message: deleteError,
        bannerVisibility: resolvedBannerVisibility,
      );
    } else {
      state = DevicesSettingsLoaded(
        devices: resolvedDevices,
        bannerVisibility: resolvedBannerVisibility,
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
    // encryptToDevice reflects whether this device will actually receive
    // room keys and be able to decrypt messages (per ShareKeysWith policy),
    // unlike directVerified/verified which the SDK force-trusts for the
    // own device regardless of any user action.
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
    await _getDevicesInteractor.execute(client: client).forEach((either) {
      either.fold(
        (failure) {
          if (failure is GetDevicesEmpty) {
            state = const DevicesSettingsLoaded(devices: []);
          } else if (failure is GetDevicesFailed) {
            state = DevicesSettingsError(exception: failure.exception);
          }
        },
        (success) {
          if (success is GetDevicesSuccess) {
            state = DevicesSettingsLoaded(devices: success.devices);
          }
        },
      );
    });
  }

  void reload() => state = const DevicesSettingsInitial();

  void setLoadingDeletingDevices(bool loading) =>
      _transition(deleting: loading);

  void setErrorDeletingDevices(String? error) =>
      _transition(deleteError: error);

  void refreshDeviceKeys() {
    final devices = _devices;
    if (devices == null) return;
    _transition(devices: List<Device>.from(devices));
  }
}
