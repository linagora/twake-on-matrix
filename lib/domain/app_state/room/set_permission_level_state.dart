import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/initial.dart';
import 'package:fluffychat/app_state/success.dart';

class SetPermissionLevelInitial extends Initial {
  @override
  List<Object?> get props => [];
}

class SetPermissionLevelLoading extends Success {
  @override
  List<Object?> get props => [];
}

class SetPermissionLevelSuccess extends Success {
  const SetPermissionLevelSuccess();

  @override
  List<Object?> get props => [];
}

class SetPermissionLevelFailure extends Failure {
  final dynamic exception;

  const SetPermissionLevelFailure({required this.exception});

  @override
  List<Object?> get props => [exception];
}

class NoPermissionFailure extends Failure {
  const NoPermissionFailure();

  @override
  List<Object?> get props => [];
}
