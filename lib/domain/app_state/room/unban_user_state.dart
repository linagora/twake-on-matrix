import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/initial.dart';
import 'package:fluffychat/app_state/success.dart';

class UnbanUserInitial extends Initial {
  @override
  List<Object?> get props => [];
}

class UnbanUserLoading extends Success {
  @override
  List<Object?> get props => [];
}

class UnbanUserSuccess extends Success {
  const UnbanUserSuccess();

  @override
  List<Object?> get props => [];
}

class UnbanUserFailure extends Failure {
  final dynamic exception;

  const UnbanUserFailure({required this.exception});

  @override
  List<Object?> get props => [exception];
}

class NoPermissionForUnbanFailure extends Failure {
  const NoPermissionForUnbanFailure();

  @override
  List<Object?> get props => [];
}
