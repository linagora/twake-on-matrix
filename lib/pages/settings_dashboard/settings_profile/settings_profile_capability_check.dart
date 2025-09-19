import 'package:dartz/dartz.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/domain/app_state/capabilities/get_server_capabilities_state.dart';
import 'package:fluffychat/domain/usecase/capabilities/get_server_capabilities_interactor.dart';
import 'package:flutter/widgets.dart';
import 'package:matrix/matrix.dart';

class SettingsProfileCapabilityCheck extends StatelessWidget {
  const SettingsProfileCapabilityCheck({
    super.key,
    required this.builder,
    this.child,
  });

  final Widget? child;
  final Widget Function(Capabilities? capabilities, Widget? child) builder;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: getIt.get<GetServerCapabilitiesInteractor>().execute(),
      builder: (context, snapshot) {
        final data = snapshot.data?.fold(id, id);
        return builder(
          data is GetServerCapabilitiesSuccess ? data.capabilities : null,
          child,
        );
      },
    );
  }
}
