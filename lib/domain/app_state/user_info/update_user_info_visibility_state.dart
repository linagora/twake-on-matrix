import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/domain/model/user_info/user_info_visibility.dart';
import 'package:fluffychat/presentation/state/success.dart';

class UpdatingUserInfoVisibility extends LoadingState {}

class UpdateUserInfoVisibilitySuccess extends Success {
  const UpdateUserInfoVisibilitySuccess(this.userInfoVisibility);

  final UserInfoVisibility userInfoVisibility;

  @override
  List<Object> get props => [userInfoVisibility];
}

class UpdateUserInfoVisibilityFailure extends Failure {
  final dynamic exception;

  const UpdateUserInfoVisibilityFailure({this.exception});

  @override
  List<Object?> get props => [exception];
}
