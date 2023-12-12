import 'package:fluffychat/app_state/failure.dart';
import 'package:matrix/matrix.dart';

class UpdateGroupChatFailure extends Failure {
  final MatrixException exception;

  const UpdateGroupChatFailure(this.exception) : super();

  @override
  List<Object?> get props => [exception];
}

class UpdateGroupAvatarFailure extends Failure {
  final dynamic exception;

  const UpdateGroupAvatarFailure({
    this.exception,
  }) : super();

  @override
  List<Object?> get props => [exception];
}

class UpdateGroupDisplayNameFailure extends Failure {
  final dynamic exception;

  const UpdateGroupDisplayNameFailure({
    this.exception,
  }) : super();

  @override
  List<Object?> get props => [exception];
}

class UpdateGroupDescriptionFailure extends Failure {
  final dynamic exception;

  const UpdateGroupDescriptionFailure({
    this.exception,
  }) : super();

  @override
  List<Object?> get props => [exception];
}

class UpdateGroupNameIsEmptyFailure extends Failure {
  const UpdateGroupNameIsEmptyFailure() : super();

  @override
  List<Object?> get props => [];
}
