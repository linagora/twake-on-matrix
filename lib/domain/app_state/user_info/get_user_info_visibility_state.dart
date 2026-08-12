import 'package:twake_chat/app_state/failure.dart';
import 'package:twake_chat/app_state/success.dart';
import 'package:twake_chat/domain/model/user_info/user_info_visibility.dart';
import 'package:twake_chat/presentation/state/success.dart';

class GettingUserInfoVisibility extends LoadingState {}

class GetUserInfoVisibilitySuccess extends Success {
  const GetUserInfoVisibilitySuccess(this.userInfoVisibility);

  final UserInfoVisibility userInfoVisibility;

  @override
  List<Object> get props => [userInfoVisibility];
}

class GetUserInfoVisibilityFailure extends Failure {
  final dynamic exception;

  const GetUserInfoVisibilityFailure({this.exception});

  @override
  List<Object?> get props => [exception];
}
