import 'package:collection/collection.dart';
import 'package:fluffychat/config/app_constants.dart';
import 'package:fluffychat/presentation/enum/chat_list/chat_list_enum.dart';
import 'package:fluffychat/utils/string_extension.dart';
import 'package:flutter/material.dart';
import 'package:fluffychat/generated/l10n/app_localizations.dart';
import 'package:matrix/matrix.dart';

extension ClientExtension on Client {
  static const int newerChat = -1;

  static const int olderChat = 1;

  int chatListItemComparator(Room room1, Room room2) {
    if (room1.isFavourite ^ room2.isFavourite) {
      return room1.isFavourite ? newerChat : olderChat;
    }
    return room2.latestEventReceivedTime.compareTo(
      room1.latestEventReceivedTime,
    );
  }

  List<Room> filteredRoomsForAll(ActiveFilter activeFilter) {
    return rooms
        .where(activeFilter.getRoomFilterByActiveFilter())
        .sorted(chatListItemComparator)
        .toList();
  }

  String mxid(BuildContext context) => userID ?? L10n.of(context)!.user;

  String? get pusherNotificationClientIdentifier => userID?.sha256Hash;

  Stream get ignoredUsersStream {
    return onSync.stream.where(
      (syncUpdate) =>
          syncUpdate.accountData?.any(
            (accountData) => accountData.type == 'm.ignored_user_list',
          ) ??
          false,
    );
  }

  String get personalInviteUrl {
    const domain = AppConstants.appLinkUniversalLinkDomain;
    const fallbackUrl = 'https://sign-up.twake.app';
    return userID == null
        ? 'https://$domain/chat?fallback=$fallbackUrl'
        : 'https://$domain/chat/${Uri.encodeComponent(userID!)}?fallback=$fallbackUrl';
  }
}
