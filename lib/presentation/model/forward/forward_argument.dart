import 'package:twake_chat/config/go_routes/router_arguments.dart';

class ForwardArgument extends RouterArguments {
  final String fromRoomId;

  ForwardArgument({required this.fromRoomId});

  @override
  List<Object?> get props => [fromRoomId];
}
