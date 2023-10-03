import 'package:fluffychat/app_state/failure.dart';

class UploadProfileFailure extends Failure {
  final dynamic exception;

  const UploadProfileFailure(this.exception) : super();

  @override
  List<Object?> get props => [exception];
}
