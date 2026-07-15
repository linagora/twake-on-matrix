import 'package:equatable/equatable.dart';
import 'package:matrix/matrix.dart';

sealed class DevicesBannerState extends Equatable {
  const DevicesBannerState();

  @override
  List<Object?> get props => [];
}

class DevicesBannerInitialState extends DevicesBannerState {}

class DisplayWarningBannerState extends DevicesBannerState {
  final List<Device> unverifiedDevices;

  const DisplayWarningBannerState({required this.unverifiedDevices});

  @override
  List<Object?> get props => [unverifiedDevices];
}
