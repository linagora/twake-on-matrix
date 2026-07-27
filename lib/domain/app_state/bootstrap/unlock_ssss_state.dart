import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';

class UnlockSsssLoadingState extends Success {
  const UnlockSsssLoadingState() : super();

  @override
  List<Object?> get props => [];
}

class UnlockSsssSuccessState extends Success {
  const UnlockSsssSuccessState() : super();

  @override
  List<Object?> get props => [];
}

class UnlockSsssFailureState extends Failure {
  final dynamic exception;

  const UnlockSsssFailureState({required this.exception});

  @override
  List<Object?> get props => [exception];
}
