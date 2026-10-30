import 'package:twake_chat/config/go_routes/router_arguments.dart';

class ForwardArgument extends RouterArguments {
  final String fromRoomId;
  final List<Map<String, Object?>> messages;

  ForwardArgument({required this.fromRoomId, required this.messages});

  @override
  List<Object?> get props => [fromRoomId, messages];
}
