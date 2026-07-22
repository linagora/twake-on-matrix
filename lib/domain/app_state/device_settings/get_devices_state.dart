import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:matrix/matrix.dart';

class GetDevicesLoading extends Success {
  const GetDevicesLoading();

  @override
  List<Object?> get props => [];
}

class GetDevicesSuccess extends Success {
  final List<Device> devices;

  const GetDevicesSuccess({required this.devices});

  @override
  List<Object?> get props => [devices];
}

class GetDevicesEmpty extends Failure {
  @override
  List<Object?> get props => [];
}

class GetDevicesFailed extends Failure {
  final dynamic exception;

  const GetDevicesFailed({this.exception});

  @override
  List<Object?> get props => [exception];
}
