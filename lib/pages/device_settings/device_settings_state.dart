import 'package:equatable/equatable.dart';
import 'package:matrix/matrix.dart';

/// State of the device-verification warning banner shown atop the list.
enum VerificationBannerVisibility { shown, dismissed }

sealed class DevicesSettingsState extends Equatable {
  const DevicesSettingsState();

  @override
  List<Object?> get props => [];
}

/// Devices have not been fetched yet.
class DevicesSettingsInitial extends DevicesSettingsState {
  const DevicesSettingsInitial();
}

/// Devices failed to load.
class DevicesSettingsError extends DevicesSettingsState {
  final dynamic exception;

  const DevicesSettingsError({this.exception});

  @override
  List<Object?> get props => [exception];
}

/// Devices loaded and idle.
class DevicesSettingsLoaded extends DevicesSettingsState {
  final List<Device> devices;
  final VerificationBannerVisibility bannerVisibility;

  const DevicesSettingsLoaded({
    required this.devices,
    this.bannerVisibility = VerificationBannerVisibility.shown,
  });

  @override
  List<Object?> get props => [devices, bannerVisibility];
}

/// The "remove all other devices" action is in flight.
class DevicesSettingsDeletingDevices extends DevicesSettingsState {
  final List<Device> devices;
  final VerificationBannerVisibility bannerVisibility;

  const DevicesSettingsDeletingDevices({
    required this.devices,
    this.bannerVisibility = VerificationBannerVisibility.shown,
  });

  @override
  List<Object?> get props => [devices, bannerVisibility];
}

/// The "remove all other devices" action failed.
class DevicesSettingsDeleteDevicesError extends DevicesSettingsState {
  final List<Device> devices;
  final VerificationBannerVisibility bannerVisibility;
  final String message;

  const DevicesSettingsDeleteDevicesError({
    required this.devices,
    required this.message,
    this.bannerVisibility = VerificationBannerVisibility.shown,
  });

  @override
  List<Object?> get props => [devices, bannerVisibility, message];
}
