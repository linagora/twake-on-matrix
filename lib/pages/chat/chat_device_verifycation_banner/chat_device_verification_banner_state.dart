import 'package:equatable/equatable.dart';

sealed class DevicesBannerState extends Equatable {
  const DevicesBannerState();

  @override
  List<Object?> get props => [];
}

class DevicesBannerInitialState extends DevicesBannerState {}

class DisplayWarningBannerState extends DevicesBannerState {
  final bool isCurrentSessionOutOfSync;

  const DisplayWarningBannerState({required this.isCurrentSessionOutOfSync});

  @override
  List<Object?> get props => [isCurrentSessionOutOfSync];
}
