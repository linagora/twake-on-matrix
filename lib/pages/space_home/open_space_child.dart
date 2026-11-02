import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:twake_chat/config/go_routes/app_routes.dart';
import 'package:twake_chat/domain/exception/spaces/space_exception.dart';
import 'package:twake_chat/domain/spaces/space_models.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:twake_chat/providers/room_list/room_list_providers.dart';
import 'package:twake_chat/utils/twake_snackbar.dart';

/// Opens what a space holds, joining it first when the user is not in it.
///
/// The router is taken before the wait: the row that asked may be gone by then.
Future<void> openSpaceChild(
  BuildContext context,
  WidgetRef ref, {
  required String parentSpaceId,
  required SpaceChannel child,
}) async {
  final router = GoRouter.of(context);
  final location = RoomRoute(roomid: child.roomId).location;
  final failed = L10n.of(context)!.spaceJoinFailed;
  if (!child.isJoined) {
    try {
      await ref
          .read(spaceJoinControllerProvider.notifier)
          .join(parentSpaceId, child);
    } on SpaceJoinFailedException {
      if (context.mounted) TwakeSnackBar.show(context, failed);
      return;
    }
  }
  router.go(location);
}
