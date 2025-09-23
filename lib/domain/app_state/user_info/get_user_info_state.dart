import 'package:fluffychat/domain/model/user_info/user_info.dart';
import 'package:fluffychat/presentation/state/failure.dart';
import 'package:fluffychat/presentation/state/success.dart';

class GettingUserInfo extends LoadingState {}

class GetUserInfoSuccess extends ViewState {
  GetUserInfoSuccess(this.userInfo);

  final UserInfo userInfo;

  @override
  List<Object> get props => [userInfo];
}

class GetUserInfoFailure extends FeatureFailure {
  const GetUserInfoFailure({super.exception});
}

class NoUserIdFailure extends FeatureFailure {
  const NoUserIdFailure({super.exception});
}
