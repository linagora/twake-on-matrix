import 'package:fluffychat/widgets/layouts/agruments/app_adaptive_scaffold_body_args.dart';

class ChatRouterInputArgument extends AbsAppAdaptiveScaffoldBodyArgs {
  final ChatRouterInputArgumentType type;

  final Object? data;

  ChatRouterInputArgument({
    required this.type,
    this.data,
    super.newActiveClient,
  });

  @override
  List<Object?> get props => [
        newActiveClient,
        type,
        data,
      ];
}

enum ChatRouterInputArgumentType {
  draft,
  share,
}
