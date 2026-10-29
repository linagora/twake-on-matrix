import 'package:twake_chat/di/global/get_it_initializer.dart';
import 'package:twake_chat/domain/app_state/capabilities/get_server_capabilities_state.dart';
import 'package:twake_chat/domain/model/user_info/user_info.dart';
import 'package:twake_chat/domain/usecase/capabilities/get_server_capabilities_interactor.dart';
import 'package:twake_chat/providers/user_info_provider.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show Consumer;
import 'package:matrix/matrix.dart';

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
      stream: getIt.get<GetServerCapabilitiesInteractor>().execute(),
      builder: (context, snapshot) {
        final capabilitiesData = snapshot.data?.fold(
          (failure) => failure,
          (success) => success,
        );
        return Consumer(
          builder: (context, ref, _) {
            final userId = this.userId;
            return builder(
              capabilitiesData is GetServerCapabilitiesSuccess
                  ? capabilitiesData.capabilities
                  : null,
              userId == null ? null : ref.watch(userInfoProvider(userId)).value,
              child,
            );
          },
        );
      },
    );
  }
}
