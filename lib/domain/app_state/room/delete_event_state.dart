import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';

class DeleteEventSuccess extends Success {
  @override
  List<Object?> get props => [];
}

class DeleteEventFailure extends Failure {
  @override
  List<Object?> get props => [];
}

class NoPermissionToDeleteEvent extends Failure {
  @override
  List<Object?> get props => [];
}

class RemoveLocalEventFailure extends Failure {
  @override
  List<Object?> get props => [];
}
