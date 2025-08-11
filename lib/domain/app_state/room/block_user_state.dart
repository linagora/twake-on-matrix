import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/initial.dart';
import 'package:fluffychat/app_state/success.dart';

class BlockUserInitial extends Initial {
  @override
  List<Object?> get props => [];
}

class BlockUserLoading extends Success {
  @override
  List<Object?> get props => [];
}

class BlockUserSuccess extends Success {
  const BlockUserSuccess();

  @override
  List<Object?> get props => [];
}

class BlockUserFailure extends Failure {
  final dynamic exception;

  const BlockUserFailure({required this.exception});

  @override
  List<Object?> get props => [exception];
}

class NoPermissionForBlockFailure extends Failure {
  const NoPermissionForBlockFailure();

  @override
  List<Object?> get props => [];
}
