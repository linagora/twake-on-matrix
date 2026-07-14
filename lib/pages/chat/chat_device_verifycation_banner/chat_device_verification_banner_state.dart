import 'package:equatable/equatable.dart';
import 'package:matrix/matrix.dart';

sealed class DevicesBannerState extends Equatable {
  const DevicesBannerState();

  @override
  List<Object?> get props => [];
}

class DevicesBannerInitialState extends DevicesBannerState {}

class DisplayWarningBannerState extends DevicesBannerState {
  final Device myDevice;

  const DisplayWarningBannerState({required this.myDevice});

  @override
  List<Object?> get props => [myDevice];
}
