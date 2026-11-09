import 'package:freezed_annotation/freezed_annotation.dart';

part 'room_list_entry.freezed.dart';

enum RoomKind { space, direct, bot, group, broadcast }

/// What the room list reads of a room, free of the Matrix SDK.
@freezed
abstract class RoomListEntry with _$RoomListEntry {
  const factory RoomListEntry({
    required String id,
    @Default('') String name,
    Uri? avatar,
    @Default(RoomKind.group) RoomKind kind,

    /// An invitation is listed but holds nothing yet.
    @Default(true) bool isJoined,

    /// A space the user may add rooms to.
    @Default(false) bool canAddChildren,
    @Default(false) bool isFavourite,

    /// Marked unread by the user, or an invitation.
    @Default(false) bool isMarkedUnread,
    @Default(0) int unreadCount,
    @Default(0) int mentionCount,

    /// The joined spaces that hold this room, those listing it first.
    @Default(<String>[]) List<String> parentSpaceIds,

    /// What this space lists, joined or not.
    @Default(<String>[]) List<String> childIds,

    /// The folders of the user this room was picked for.
    @Default(<String>[]) List<String> folders,
  }) = _RoomListEntry;

  const RoomListEntry._();

  bool get isSpace => kind == RoomKind.space;

  /// A direct chat, with a person or a bot.
  bool get isDirect => kind == RoomKind.direct || kind == RoomKind.bot;

  bool get isUnread => isMarkedUnread || unreadCount > 0 || mentionCount > 0;
}
