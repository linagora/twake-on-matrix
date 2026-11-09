import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:twake_chat/config/go_routes/app_routes.dart';
import 'package:twake_chat/pages/space_home/space_home_controller.dart';

/// A joined space shows its home, for it is no conversation; anything else
/// shows the conversation. A space the user left or was removed from has
/// nothing to show: back to the list.
class SpaceOrChat extends ConsumerWidget {
  const SpaceOrChat({
    super.key,
    required this.roomId,
    required this.spaceBuilder,
    required this.chatBuilder,
  });

  final String roomId;
  final WidgetBuilder spaceBuilder;
  final WidgetBuilder chatBuilder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSpaceProvider = spaceHomeControllerProvider(
      roomId,
    ).select((state) => state.space != null);
    ref.listen(isSpaceProvider, (wasSpace, isSpace) {
      if (wasSpace == true && !isSpace) const RoomsRoute().go(context);
    });
    return ref.watch(isSpaceProvider)
        ? spaceBuilder(context)
        : chatBuilder(context);
  }
}
