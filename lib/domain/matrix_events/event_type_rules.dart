import 'package:matrix/matrix.dart';
import 'package:twake_chat/domain/matrix_events/call_event_types.dart';

/// How a given event type behaves in the chat timeline.
enum EventVisibilityGroup {
  /// Survives all visibility toggles (messages, important state events).
  alwaysVisible,

  /// Hidden when [AppConfig.hideUnimportantStateEvents] is true.
  unimportant,

  /// Never shown in timeline or chat-list preview.
  neverInTimeline,

  /// Hidden when [AppConfig.hideUnknownEvents] is true.
  /// Also the fallback for types absent from [EventTypeRules._byType],
  /// call events aside.
  unknown,
}

/// Per-type rule: visibility group and UI flags for a Matrix event type.
class EventTypeRule {
  final EventVisibilityGroup group;

  /// User-produced content (messages, encrypted payloads).
  /// Used by widget type guards and "has messages" checks.
  final bool isUserContent;

  /// Subset of [isUserContent]: carries a displayable message body.
  /// Used for same-sender grouping and local notifications.
  final bool isMessageContent;

  /// Whether this event type can appear as the "last message" preview
  /// in the chat list.
  final bool showInChatList;

  const EventTypeRule({
    required this.group,
    this.isUserContent = false,
    this.isMessageContent = false,
    this.showInChatList = false,
  });
}

/// Canonical Matrix event-type rules for filtering, grouping and display.
///
/// Every type-based visibility decision should go through [getGroup] or one of
/// the derived sets so the codebase has a single source of truth.
abstract final class EventTypeRules {
  static const Map<String, EventTypeRule> _byType = {
    // -- Always visible -------------------------------------------------------
    EventTypes.Message: EventTypeRule(
      group: EventVisibilityGroup.alwaysVisible,
      isUserContent: true,
      isMessageContent: true,
      showInChatList: true,
    ),
    EventTypes.Encrypted: EventTypeRule(
      group: EventVisibilityGroup.alwaysVisible,
      isUserContent: true,
      isMessageContent: true,
      showInChatList: true,
    ),
    EventTypes.Sticker: EventTypeRule(
      group: EventVisibilityGroup.alwaysVisible,
      isUserContent: true,
      isMessageContent: true,
      showInChatList: false,
    ),
    EventTypes.RoomMember: EventTypeRule(
      group: EventVisibilityGroup.alwaysVisible,
    ),
    EventTypes.RoomName: EventTypeRule(
      group: EventVisibilityGroup.alwaysVisible,
    ),
    EventTypes.RoomAvatar: EventTypeRule(
      group: EventVisibilityGroup.alwaysVisible,
    ),
    EventTypes.RoomCreate: EventTypeRule(
      group: EventVisibilityGroup.alwaysVisible,
    ),
    EventTypes.RoomTombstone: EventTypeRule(
      group: EventVisibilityGroup.alwaysVisible,
    ),

    // -- Unimportant (hidden by hideUnimportantStateEvents) -------------------
    EventTypes.Encryption: EventTypeRule(
      group: EventVisibilityGroup.unimportant,
    ),
    EventTypes.GuestAccess: EventTypeRule(
      group: EventVisibilityGroup.unimportant,
    ),
    EventTypes.HistoryVisibility: EventTypeRule(
      group: EventVisibilityGroup.unimportant,
    ),
    EventTypes.RoomJoinRules: EventTypeRule(
      group: EventVisibilityGroup.unimportant,
    ),
    EventTypes.RoomPowerLevels: EventTypeRule(
      group: EventVisibilityGroup.unimportant,
    ),
    EventTypes.RoomTopic: EventTypeRule(
      group: EventVisibilityGroup.unimportant,
    ),

    // -- Never in timeline ----------------------------------------------------
    // Reactions are aggregated on the parent event, not rendered as rows.
    EventTypes.Reaction: EventTypeRule(
      group: EventVisibilityGroup.neverInTimeline,
    ),
    // m.room.redaction is a control event. The redacted *original* event still
    // renders as a "Deleted message" bubble in the timeline.
    EventTypes.Redaction: EventTypeRule(
      group: EventVisibilityGroup.neverInTimeline,
    ),
    EventTypes.RoomPinnedEvents: EventTypeRule(
      group: EventVisibilityGroup.neverInTimeline,
    ),
    EventTypes.RoomCanonicalAlias: EventTypeRule(
      group: EventVisibilityGroup.neverInTimeline,
    ),
    'm.room.server_acl': EventTypeRule(
      group: EventVisibilityGroup.neverInTimeline,
    ),

    // The legacy invite is a single line; other call events never show.
    EventTypes.CallInvite: EventTypeRule(
      group: EventVisibilityGroup.alwaysVisible,
    ),
  };

  /// Returns the visibility group for [type], or [EventVisibilityGroup.unknown]
  /// for unregistered types.
  static EventVisibilityGroup getGroup(String type) =>
      _byType[type]?.group ??
      (CallEventTypes.isCallEvent(type)
          ? EventVisibilityGroup.neverInTimeline
          : EventVisibilityGroup.unknown);

  /// Message-like types (same-sender grouping, notifications, server filter).
  static final Set<String> messageContentTypes = {
    for (final e in _byType.entries)
      if (e.value.isMessageContent) e.key,
  };

  static bool isStateEventType(String type) =>
      !messageContentTypes.contains(type);

  /// All user-produced content types (widget type guards, "has messages" checks).
  static final Set<String> userContentTypes = {
    for (final e in _byType.entries)
      if (e.value.isUserContent) e.key,
  };

  /// Event types eligible for the chat-list "last message" preview.
  static final Set<String> showInChatListTypes = {
    for (final e in _byType.entries)
      if (e.value.showInChatList) e.key,
  };
}
