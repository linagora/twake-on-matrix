import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:twake_chat/di/global/get_it_initializer.dart';
import 'package:twake_chat/domain/app_state/user_info/get_user_info_state.dart';
import 'package:twake_chat/domain/capabilities/models/profile_edit_capabilities.dart';
import 'package:twake_chat/domain/model/user_info/user_info.dart';
import 'package:twake_chat/domain/usecase/user_info/get_user_info_interactor.dart';
import 'package:flutter/widgets.dart';
import 'package:twake_chat/pages/settings_dashboard/settings_profile/profile_edit_capabilities_provider.dart';

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
    ProfileEditCapabilities? capabilities,
    UserInfo? userInfo,
    Widget? child,
  )
  builder;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: getIt.get<GetUserInfoInteractor>().execute(userId: userId),
      builder: (context, snapshot) {
        final userInfoData = snapshot.data?.fold(
          (failure) => failure,
          (success) => success,
        );
        return Consumer(
          builder: (context, ref, child) => builder(
            ref.watch(profileEditCapabilitiesProvider).unwrapPrevious().value,
            userInfoData is GetUserInfoSuccess ? userInfoData.userInfo : null,
            child,
          ),
          child: child,
        );
      },
    );
  }
}
