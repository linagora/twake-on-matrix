import 'package:fluffychat/app_state/failure.dart';

class SendFilesFailed extends Failure {
  final dynamic exception;

  const SendFilesFailed({required this.exception});

  @override
  List<Object?> get props => [exception];
}
