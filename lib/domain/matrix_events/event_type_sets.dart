import 'package:matrix/matrix.dart';

/// Canonical event-type sets used for filtering, grouping and display.
abstract final class EventTypeSets {
  /// Message-like types: messages, stickers, encrypted payloads.
  static const Set<String> messageContentTypes = {
    EventTypes.Message,
    EventTypes.Sticker,
    EventTypes.Encrypted,
  };

  static const List<String> messageContentTypesList = [
    EventTypes.Message,
    EventTypes.Sticker,
    EventTypes.Encrypted,
  ];

  /// [messageContentTypes] + signalling types produced by users (calls).
  static const Set<String> userContentTypes = {
    EventTypes.Message,
    EventTypes.Sticker,
    EventTypes.Encrypted,
    EventTypes.CallInvite,
  };

  /// State events kept visible when "hide unimportant state events" is on.
  static const Set<String> importantStateEvents = {
    EventTypes.Encryption,
    EventTypes.RoomCreate,
    EventTypes.RoomMember,
    EventTypes.RoomTombstone,
    EventTypes.CallInvite,
    EventTypes.RoomName,
    EventTypes.RoomAvatar,
  };
}
