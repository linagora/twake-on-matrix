import 'package:fluffychat/app_state/failure.dart';

class GetRecoveryWordsFailed extends Failure {
  final dynamic exception;

  const GetRecoveryWordsFailed({required this.exception});

  @override
  List<Object?> get props => [exception];
}
