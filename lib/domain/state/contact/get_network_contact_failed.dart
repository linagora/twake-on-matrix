import 'package:fluffychat/state/failure.dart';

class GetNetworkContactFailed extends Failure {

  final dynamic exception;

  const GetNetworkContactFailed({required this.exception});

  @override
  List<Object?> get props => [exception];

}