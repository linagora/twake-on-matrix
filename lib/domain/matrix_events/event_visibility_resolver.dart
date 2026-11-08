import 'package:twake_chat/config/app_config.dart';
import 'package:twake_chat/domain/matrix_events/event_type_rules.dart';
import 'package:twake_chat/domain/model/thread/thread_relation_extension.dart';
import 'package:matrix/matrix.dart';

/// Single entry-point for all event visibility decisions.
abstract final class EventVisibilityResolver {
  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Whether [event] should be rendered as a row in the chat timeline.
  ///
  /// Rules are evaluated in layers, short-circuiting on the first `false`:
  /// 1. Relationship — edits/reactions/verification are always hidden, and
  ///    thread replies outside the thread screen.
  /// 2. Type         — delegates to [EventTypeRules].
  /// 3. Config       — [AppConfig] toggles.
  /// 4. Content      — payload / room-state heuristics.
  ///
  /// [inThread] is true on the thread screen, where thread replies are the
  /// content and must not be hidden.
  ///
  /// [knownThreadReplyIds]: ids of events seen as thread replies; one of them
  /// stays out of the main timeline even once deleted (a deleted event loses
  /// its relation).
  static bool isVisibleInTimeline(
    Event event, {
    bool inThread = false,
    Set<String> knownThreadReplyIds = const {},
  }) {
    return _passesRelationshipLayer(
          event,
          inThread: inThread,
          knownThreadReplyIds: knownThreadReplyIds,
        ) &&
        _passesTypeLayer(event) &&
        _passesConfigLayer(event) &&
        _passesContentLayer(event);
  }

  /// Synchronous fast-path for [isEligibleForChatListPreview].
  ///
  /// Checks type and redaction only. Edit-chain traversal is intentionally
  /// omitted because it requires [Room.getEventById] (async). Callers that
  /// need full accuracy must use [isEligibleForChatListPreview].
  static bool isEligibleForChatListPreviewSync(Event event) {
    if (!EventTypeRules.showInChatListTypes.contains(event.type)) return false;
    if (event.redacted) return false;
    if (event.threadRootId != null) return false;
    return true;
  }

  /// Whether [event] may be used as the "last message" preview in the chat
  /// list. Async because edit-chain traversal requires [Room.getEventById].
  static Future<bool> isEligibleForChatListPreview(
    Room room,
    Event event,
  ) async {
    if (!EventTypeRules.showInChatListTypes.contains(event.type)) return false;
    if (event.redacted) return false;
    if (event.threadRootId != null) return false;
    if (event.relationshipType != RelationshipTypes.edit) return true;

    // Walk the edit chain; discard if any ancestor is redacted.
    final visited = <String>{};
    var id = event.relationshipEventId;
    while (id != null) {
      if (!visited.add(id)) break;
      final target = await room.getEventById(id);
      if (target == null) break;
      if (target.redacted || target.threadRootId != null) return false;
      id = target.relationshipType == RelationshipTypes.edit
          ? target.relationshipEventId
          : null;
    }
    return true;
  }

  // ---------------------------------------------------------------------------
  // Layer 1 — Relationship
  // ---------------------------------------------------------------------------

  static const _hiddenRelationships = {
    RelationshipTypes.edit,
    RelationshipTypes.reaction,
  };

  static bool _passesRelationshipLayer(
    Event event, {
    bool inThread = false,
    Set<String> knownThreadReplyIds = const {},
  }) {
    if (_hiddenRelationships.contains(event.relationshipType)) return false;
    if (!inThread &&
        (event.threadRootId != null ||
            knownThreadReplyIds.contains(event.eventId))) {
      return false;
    }
    if (event.type.startsWith('m.key.verification.')) return false;
    return true;
  }

  // ---------------------------------------------------------------------------
  // Layer 2 — Type
  // ---------------------------------------------------------------------------

  static bool _passesTypeLayer(Event event) {
    return EventTypeRules.getGroup(event.type) !=
        EventVisibilityGroup.neverInTimeline;
  }

  // ---------------------------------------------------------------------------
  // Layer 3 — Config
  // ---------------------------------------------------------------------------

  static bool _passesConfigLayer(Event event) {
    final group = EventTypeRules.getGroup(event.type);
    if (group == EventVisibilityGroup.unknown && AppConfig.hideUnknownEvents) {
      return false;
    }
    if (AppConfig.hideAllStateEvents &&
        EventTypeRules.isStateEventType(event.type)) {
      return false;
    }
    if (group == EventVisibilityGroup.unimportant &&
        AppConfig.hideUnimportantStateEvents) {
      return false;
    }
    return true;
  }

  // ---------------------------------------------------------------------------
  // Layer 4 — Content / room-context heuristics
  // ---------------------------------------------------------------------------

  static bool _passesContentLayer(Event event) =>
      !_contentRules.any((rule) => rule(event));

  /// Add new rules here without touching the layer dispatch above.
  static final List<bool Function(Event)> _contentRules = [
    _isMemberEventInPublicRoomUnimportant,
    _isSomeoneChangeDisplayName,
    _isSomeoneChangeAvatar,
    _isGroupNamePlaceholder,
    _isGroupAvatarPlaceholder,
    _isJoinedByYourself,
    _isInviteWithoutReason,
  ];

  static bool _isMemberEventInPublicRoomUnimportant(Event event) {
    if (!AppConfig.hideUnimportantStateEvents) return false;
    return event.type == EventTypes.RoomMember &&
        event.room.joinRules == JoinRules.public &&
        event.content.tryGet<String>('membership') != 'ban' &&
        event.stateKey == event.senderId;
  }

  static bool _isSomeoneChangeDisplayName(Event event) {
    return event.type == EventTypes.RoomMember &&
        event.stateKey != null &&
        event.content['membership'] == 'join' &&
        event.prevContent?['membership'] == 'join' &&
        event.prevContent?['displayname'] != null &&
        event.prevContent!['displayname'] != event.content['displayname'];
  }

  static bool _isSomeoneChangeAvatar(Event event) {
    return event.type == EventTypes.RoomMember &&
        event.stateKey != null &&
        event.content['membership'] == 'join' &&
        event.prevContent?['membership'] == 'join' &&
        event.prevContent?['avatar_url'] != event.content['avatar_url'];
  }

  static bool _isGroupNamePlaceholder(Event event) {
    return event.type == EventTypes.RoomName &&
        event.prevContent?['name'] == null &&
        event.content['name'] == null;
  }

  static bool _isGroupAvatarPlaceholder(Event event) {
    return event.type == EventTypes.RoomAvatar &&
        event.prevContent?['url'] == null &&
        event.content['url'] == null;
  }

  static bool _isJoinedByYourself(Event event) {
    return event.type == EventTypes.RoomMember &&
        event.content['membership'] == 'join' &&
        event.senderId == event.stateKey &&
        event.stateKey == event.room.client.userID;
  }

  static bool _isInviteWithoutReason(Event event) {
    return event.type == EventTypes.RoomMember &&
        event.prevContent == null &&
        event.content['membership'] == 'invite' &&
        event.content['reason'] == null;
  }
}
