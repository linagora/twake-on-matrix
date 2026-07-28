import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/domain/app_state/capabilities/get_server_capabilities_state.dart';
import 'package:fluffychat/domain/app_state/user_info/get_user_info_state.dart';
import 'package:fluffychat/domain/model/user_info/user_info.dart';
import 'package:fluffychat/domain/usecase/capabilities/get_server_capabilities_interactor.dart';
import 'package:fluffychat/domain/usecase/user_info/get_user_info_interactor.dart';
import 'package:flutter/widgets.dart';
import 'package:matrix/matrix.dart';
import 'package:rxdart/rxdart.dart';

class SettingsProfileCapabilityCheck extends StatelessWidget {
  const SettingsProfileCapabilityCheck({
    super.key,
    required this.builder,
    this.child,
    this.userId,
  });

  final Widget? child;
  final String? userId;
  final Widget Function(
    Capabilities? capabilities,
    UserInfo? userInfo,
    Widget? child,
  )
  builder;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: Rx.combineLatest2(
        getIt.get<GetServerCapabilitiesInteractor>().execute(),
        getIt.get<GetUserInfoInteractor>().execute(userId: userId),
        (capabilitiesState, userInfoState) => (
          capabilitiesState: capabilitiesState,
          userInfoState: userInfoState,
        ),
      ),
      builder: (context, snapshot) {
        final capabilitiesData = snapshot.data?.capabilitiesState.fold(
          (failure) => failure,
          (success) => success,
        );
        final userInfoData = snapshot.data?.userInfoState.fold(
          (failure) => failure,
          (success) => success,
        );
        return builder(
          capabilitiesData is GetServerCapabilitiesSuccess
              ? capabilitiesData.capabilities
              : null,
          userInfoData is GetUserInfoSuccess ? userInfoData.userInfo : null,
          child,
        );
      },
    );
  }
}
