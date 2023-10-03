import 'package:fluffychat/app_state/failure.dart';

class UpdateProfileFailure extends Failure {
  final dynamic exception;

  const UpdateProfileFailure(this.exception) : super();

  @override
  List<Object?> get props => [exception];
}
