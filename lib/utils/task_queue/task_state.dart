import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';

class TaskSuccess extends Success {
  final dynamic result;

  const TaskSuccess({this.result});

  @override
  List<Object?> get props => [result];
}

class TaskFailure extends Failure {
  final dynamic exception;

  const TaskFailure({this.exception});

  @override
  List<Object?> get props => [exception];
}
