
import 'package:fluffychat/app_state/failure.dart';

class GetLocalContactFailed extends Failure {

  final dynamic exception;

  const GetLocalContactFailed({required this.exception});

  @override
  List<Object?> get props => [exception];

}