import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/initial.dart';
import 'package:fluffychat/app_state/success.dart';

class BanUserInitial extends Initial {
  @override
  List<Object?> get props => [];
}

class BanUserLoading extends Success {
  @override
  List<Object?> get props => [];
}

class BanUserSuccess extends Success {
  const BanUserSuccess();

  @override
  List<Object?> get props => [];
}

class BanUserFailure extends Failure {
  final dynamic exception;

  const BanUserFailure({required this.exception});

  @override
  List<Object?> get props => [exception];
}

class NoPermissionForBanFailure extends Failure {
  const NoPermissionForBanFailure();

  @override
  List<Object?> get props => [];
}
