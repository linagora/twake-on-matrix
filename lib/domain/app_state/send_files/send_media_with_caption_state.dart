import 'package:fluffychat/app_state/failure.dart';

class SendMediaWithCaptionFailed extends Failure {
  final dynamic exception;

  const SendMediaWithCaptionFailed({required this.exception});

  @override
  List<Object?> get props => [exception];
}
