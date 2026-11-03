import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:twake_chat/config/go_routes/app_routes.dart';
import 'package:twake_chat/domain/exception/spaces/space_exception.dart';
import 'package:twake_chat/domain/spaces/space_models.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:twake_chat/providers/room_list/room_list_providers.dart';
import 'package:twake_chat/utils/responsive/responsive_utils.dart';
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
  // A phone shows one page at a time: back must return to the space.
  final keepsThePage = ResponsiveUtils().isSingleColumnLayout(context);
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
  if (keepsThePage) {
    unawaited(router.push(location));
  } else {
    router.go(location);
  }
}
