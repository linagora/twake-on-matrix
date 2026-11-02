import 'package:twake_chat/config/go_routes/router_arguments.dart';

class ForwardArgument extends RouterArguments {
  final List<Map<String, Object?>> messages;

  ForwardArgument({required this.messages});

  @override
  List<Object?> get props => [messages];
}
