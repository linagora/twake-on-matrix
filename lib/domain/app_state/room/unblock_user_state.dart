import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/initial.dart';
import 'package:fluffychat/app_state/success.dart';

class UnblockUserInitial extends Initial {
  @override
  List<Object?> get props => [];
}

class UnblockUserLoading extends Success {
  @override
  List<Object?> get props => [];
}

class UnblockUserSuccess extends Success {
  const UnblockUserSuccess();

  @override
  List<Object?> get props => [];
}

class UnblockUserFailure extends Failure {
  final dynamic exception;

  const UnblockUserFailure({required this.exception});

  @override
  List<Object?> get props => [exception];
}

class NoPermissionForUnblockFailure extends Failure {
  const NoPermissionForUnblockFailure();

  @override
  List<Object?> get props => [];
}
