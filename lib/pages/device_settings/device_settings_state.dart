import 'package:equatable/equatable.dart';
import 'package:matrix/matrix.dart';

class DevicesSettingsState extends Equatable {
  final List<Device>? devices;
  final bool loadingDeletingDevices;
  final String? errorDeletingDevices;
  final bool verificationBannerDismissed;

  const DevicesSettingsState({
    this.devices,
    this.loadingDeletingDevices = false,
    this.errorDeletingDevices,
    this.verificationBannerDismissed = false,
  });

  DevicesSettingsState copyWith({
    List<Device>? devices,
    bool clearDevices = false,
    bool? loadingDeletingDevices,
    String? errorDeletingDevices,
    bool clearErrorDeletingDevices = false,
    bool? verificationBannerDismissed,
  }) {
    return DevicesSettingsState(
      devices: clearDevices ? null : (devices ?? this.devices),
      loadingDeletingDevices:
          loadingDeletingDevices ?? this.loadingDeletingDevices,
      errorDeletingDevices: clearErrorDeletingDevices
          ? null
          : (errorDeletingDevices ?? this.errorDeletingDevices),
      verificationBannerDismissed:
          verificationBannerDismissed ?? this.verificationBannerDismissed,
    );
  }

  @override
  List<Object?> get props => [
    devices,
    loadingDeletingDevices,
    errorDeletingDevices,
    verificationBannerDismissed,
  ];
}
