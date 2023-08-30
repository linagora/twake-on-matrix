import 'package:equatable/equatable.dart';

class ChatRouterInputArgument with EquatableMixin {
  final ChatRouterInputArgumentType type;

  final Object? data;

  ChatRouterInputArgument({
    required this.type,
    this.data,
  });

  @override
  List<Object?> get props => [
        type,
        data,
      ];
}

enum ChatRouterInputArgumentType {
  draft,
  share,
}
