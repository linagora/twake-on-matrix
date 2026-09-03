import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:matrix/matrix.dart';

part 'device_settings_state.freezed.dart';

/// State of the device-verification warning banner shown atop the list.
enum VerificationBannerVisibility { shown, dismissed }

@freezed
sealed class DevicesSettingsState with _$DevicesSettingsState {
  /// Devices have not been fetched yet.
  const factory DevicesSettingsState.initial() = DevicesSettingsInitial;

  /// Devices failed to load.
  const factory DevicesSettingsState.error({dynamic exception}) =
      DevicesSettingsError;

  /// Devices loaded and idle.
  const factory DevicesSettingsState.loaded({
    required List<Device> devices,
    @Default(VerificationBannerVisibility.shown)
    VerificationBannerVisibility bannerVisibility,

    /// Bumped when device-key trust changes without the [Device] list
    /// changing, so Riverpod notifies listeners (e.g. after SAS verify).
    @Default(0) int keysRevision,
  }) = DevicesSettingsLoaded;

  /// The "remove all other devices" action is in flight.
  const factory DevicesSettingsState.deletingDevices({
    required List<Device> devices,
    @Default(VerificationBannerVisibility.shown)
    VerificationBannerVisibility bannerVisibility,
    @Default(0) int keysRevision,
  }) = DevicesSettingsDeletingDevices;

  /// The "remove all other devices" action failed.
  const factory DevicesSettingsState.deleteDevicesError({
    required List<Device> devices,
    required String message,
    @Default(VerificationBannerVisibility.shown)
    VerificationBannerVisibility bannerVisibility,
    @Default(0) int keysRevision,
  }) = DevicesSettingsDeleteDevicesError;
}
