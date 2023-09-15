import 'package:fluffychat/app_state/failure.dart';

class GetPreviewURLFailure extends Failure {
  final dynamic exception;

  const GetPreviewURLFailure(this.exception) : super();

  @override
  List<Object?> get props => [exception];
}
