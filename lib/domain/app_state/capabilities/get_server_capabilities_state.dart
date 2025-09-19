import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/presentation/state/failure.dart';
import 'package:fluffychat/presentation/state/success.dart';
import 'package:matrix/matrix.dart';

class GettingServerCapabilities extends LoadingState {}

class GetServerCapabilitiesSuccess extends Success {
  const GetServerCapabilitiesSuccess(this.capabilities);

  final Capabilities capabilities;

  @override
  List<Object?> get props => [capabilities];
}

class GetServerCapabilitiesFailure extends FeatureFailure {
  const GetServerCapabilitiesFailure({super.exception});
}
