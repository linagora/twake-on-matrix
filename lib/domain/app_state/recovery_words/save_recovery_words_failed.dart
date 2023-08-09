import 'package:fluffychat/app_state/failure.dart';

class SaveRecoveryWordsFailed extends Failure {
  final dynamic exception;

  const SaveRecoveryWordsFailed({this.exception});

  @override
  List<Object?> get props => [exception];
}
