import 'package:equatable/equatable.dart';

sealed class DevicesBannerState extends Equatable {
  const DevicesBannerState();

  @override
  List<Object?> get props => [];
}

class DevicesBannerInitialState extends DevicesBannerState {}

class DisplayWarningBannerState extends DevicesBannerState {
  const DisplayWarningBannerState();

  @override
  List<Object?> get props => [];
}
