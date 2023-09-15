import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';

class DeleteRecoveryWordsFailed extends Failure {
  final dynamic exception;

  const DeleteRecoveryWordsFailed({this.exception});

  @override
  List<Object?> get props => [exception];
}

class DeleteRecoveryWordsSuccess extends Success {
  const DeleteRecoveryWordsSuccess();

  @override
  List<Object?> get props => [];
}
