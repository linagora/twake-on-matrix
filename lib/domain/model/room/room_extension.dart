import 'package:collection/collection.dart';
import 'package:fluffychat/config/default_power_level_member.dart';
import 'package:fluffychat/domain/matrix_events/event_type_rules.dart';
import 'package:fluffychat/domain/matrix_events/event_visibility_resolver.dart';
import 'package:fluffychat/data/network/extensions/file_info_extension.dart';
import 'package:fluffychat/domain/model/file_info/file_info.dart';
import 'package:fluffychat/domain/model/room/room_preview_result.dart';
import 'package:fluffychat/domain/model/search/recent_chat_model.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions/client_stories_extension.dart';
import 'package:html_unescape/html_unescape.dart';
import 'package:matrix/matrix.dart';
// ignore: implementation_imports
import 'package:matrix/src/utils/markdown.dart';

extension RoomExtension on Room {
  RecentChatSearchModel toRecentChatSearchModel(
    MatrixLocalizations matrixLocalizations,
  ) {
    return RecentChatSearchModel(
      id,
      displayName: getLocalizedDisplayname(matrixLocalizations),
      roomSummary: summary,
      directChatMatrixID: directChatMatrixID,
    );
  }

  bool isNotSpaceAndStoryRoom() {
    return !isSpace && !isStoryRoom;
  }

  bool isShowInChatList() {
    return _isDirectChatHaveMessage() || _isGroupChat();
  }

  bool _isGroupChat() {
    return !isDirectChat;
  }

  bool _isDirectChatHaveMessage() {
    return isDirectChat && _isLastEventInRoomIsMessage();
  }

  bool _isLastEventInRoomIsMessage() {
    return EventTypeRules.messageContentTypes.contains(lastEvent?.type);
  }

  Future<void> mute() async {
    await setPushRuleState(PushRuleState.mentionsOnly);
  }

  Future<void> unmute() async {
    await setPushRuleState(PushRuleState.notify);
  }

  bool get isMuted {
    return pushRuleState != PushRuleState.notify;
  }

  Future<String> storePlaceholderFileInMem({
    required FileInfo fileInfo,
    String? txid,
  }) async {
    txid ??= client.generateUniqueTransactionId();
    final matrixFile = await fileInfo.toMatrixFile();
    sendingFilePlaceholders[txid] = matrixFile;
    return txid;
  }

  bool get isInvitation {
    return membership == Membership.invite;
  }

  bool get canPinMessage {
    final currentPowerLevelsMap = getState(EventTypes.RoomPowerLevels)?.content;
    if (currentPowerLevelsMap == null) return 0 <= ownPowerLevel;
    return (currentPowerLevelsMap
                .tryGetMap<String, Object?>('events')
                ?.tryGet<int>(EventTypes.RoomPinnedEvents) ??
            getDefaultPowerLevel(currentPowerLevelsMap)) <=
        ownPowerLevel;
  }

  bool get canSendReactions {
    final currentPowerLevelsMap = getState(EventTypes.RoomPowerLevels)?.content;
    if (currentPowerLevelsMap == null) return 0 <= ownPowerLevel;
    return (currentPowerLevelsMap
                .tryGetMap<String, Object?>('events')
                ?.tryGet<int>(EventTypes.Reaction) ??
            getDefaultPowerLevel(currentPowerLevelsMap)) <=
        ownPowerLevel;
  }

  bool get canChangeRoomName {
    final currentPowerLevelsMap = getState(EventTypes.RoomPowerLevels)?.content;
    if (currentPowerLevelsMap == null) return 0 <= ownPowerLevel;
    return (currentPowerLevelsMap
                .tryGetMap<String, Object?>('events')
                ?.tryGet<int>(EventTypes.RoomName) ??
            currentPowerLevelsMap.tryGet<int>('state_default') ??
            80) <=
        ownPowerLevel;
  }

  bool get canChangeTopic {
    final currentPowerLevelsMap = getState(EventTypes.RoomPowerLevels)?.content;
    if (currentPowerLevelsMap == null) return 0 <= ownPowerLevel;
    return (currentPowerLevelsMap
                .tryGetMap<String, Object?>('events')
                ?.tryGet<int>(EventTypes.RoomTopic) ??
            currentPowerLevelsMap.tryGet<int>('state_default') ??
            80) <=
        ownPowerLevel;
  }

  bool get canChangeRoomAvatar {
    final currentPowerLevelsMap = getState(EventTypes.RoomPowerLevels)?.content;
    if (currentPowerLevelsMap == null) return 0 <= ownPowerLevel;
    return (currentPowerLevelsMap
                .tryGetMap<String, Object?>('events')
                ?.tryGet<int>(EventTypes.RoomAvatar) ??
            currentPowerLevelsMap.tryGet<int>('state_default') ??
            80) <=
        ownPowerLevel;
  }

  bool get canEnableEncryption {
    final currentPowerLevelsMap = getState(EventTypes.RoomPowerLevels)?.content;
    if (currentPowerLevelsMap == null) return 0 <= ownPowerLevel;
    return (currentPowerLevelsMap
                .tryGetMap<String, Object?>('events')
                ?.tryGet<int>(EventTypes.Encryption) ??
            currentPowerLevelsMap.tryGet<int>('state_default') ??
            80) <=
        ownPowerLevel;
  }

  bool get canEditChatDetails {
    return canChangeRoomName ||
        canChangeTopic ||
        canChangeRoomAvatar ||
        canEnableEncryption ||
        canChangePowerLevel ||
        canAssignRoles;
  }

  bool get canSendRedactEvent {
    final currentPowerLevelsMap = getState(EventTypes.RoomPowerLevels)?.content;
    if (currentPowerLevelsMap == null) return 0 <= ownPowerLevel;
    return (currentPowerLevelsMap
                .tryGetMap<String, Object?>('events')
                ?.tryGet<int>(EventTypes.Redaction) ??
            getDefaultPowerLevel(currentPowerLevelsMap)) <=
        ownPowerLevel;
  }

  bool get canRedactEventSentByOther {
    if (!canSendRedactEvent) return false;
    return canRedact;
  }

  /// Returns the most recent event eligible for the chat-list "last message"
  /// preview.
  ///
  /// - [RoomPreviewFound]       — an eligible event was found.
  /// - [RoomPreviewEmpty]       — the full history was scanned (m.room.create
  ///                              reached) with no eligible event.
  /// - [RoomPreviewUnavailable] — the scan window was exhausted before
  ///                              m.room.create: history may contain eligible
  ///                              events beyond the scanned window.
  Future<RoomPreviewResult> lastEventAvailableInPreview() async {
    const previewLimit = 30;
    try {
      final statePreviewCandidates = client.roomPreviewLastEvents
          .map(getState)
          .whereType<Event>()
          .toList();
      Event? best;
      for (final e in statePreviewCandidates) {
        if (await EventVisibilityResolver.isEligibleForChatListPreview(
          this,
          e,
        )) {
          best = _newestEvent(best, e);
        }
      }
      if (best != null) {
        return RoomPreviewFound(best);
      }

      final dbEvents = await client.database.getEventList(
        this,
        limit: previewLimit,
      );
      var roomFullyScanned = false;
      for (final e in dbEvents) {
        if (e.type == EventTypes.RoomCreate) roomFullyScanned = true;
        if (await EventVisibilityResolver.isEligibleForChatListPreview(
          this,
          e,
        )) {
          best = _newestEvent(best, e);
        }
      }
      if (best != null) {
        return RoomPreviewFound(best);
      }
      return roomFullyScanned
          ? const RoomPreviewEmpty()
          : const RoomPreviewUnavailable();
    } catch (e) {
      Logs().e('Room::lastEventAvailableInPreview: room: $id error - $e');
      return const RoomPreviewUnavailable();
    }
  }

  /// Picks the newest of two events. At equal timestamps, prefers the
  /// non-encrypted variant (the SDK may expose the same event both encrypted
  /// and decrypted in state).
  static Event _newestEvent(Event? a, Event b) {
    if (a == null) return b;
    if (a.originServerTs == b.originServerTs) {
      return a.type == EventTypes.Encrypted ? b : a;
    }
    return a.originServerTs.millisecondsSinceEpoch >
            b.originServerTs.millisecondsSinceEpoch
        ? a
        : b;
  }

  bool get canAssignRoles {
    final currentPowerLevelsMap = getState(EventTypes.RoomPowerLevels)?.content;
    if (currentPowerLevelsMap == null) return 0 <= ownPowerLevel;
    return (currentPowerLevelsMap
                .tryGetMap<String, Object?>('events')
                ?.tryGet<int>(EventTypes.RoomPowerLevels) ??
            currentPowerLevelsMap.tryGet<int>('state_default') ??
            DefaultPowerLevelMember.admin.powerLevel) <=
        ownPowerLevel;
  }

  List<User> getAssignRolesMember() {
    final members = getParticipants();
    if (members.isEmpty) return [];
    return members.where((final User member) {
        final powerLevel = member.powerLevel;
        return powerLevel >= DefaultPowerLevelMember.moderator.powerLevel &&
            member.membership == Membership.join;
      }).toList()
      ..sort((small, great) => great.powerLevel.compareTo(small.powerLevel));
  }

  List<User> getExceptionsMember() {
    final members = getParticipants();
    if (members.isEmpty) return [];
    return members.where((final User member) {
        final powerLevel = member.powerLevel;
        return powerLevel < DefaultPowerLevelMember.member.powerLevel &&
            member.membership == Membership.join;
      }).toList()
      ..sort((small, great) => great.powerLevel.compareTo(small.powerLevel));
  }

  List<User> getBannedMembers() {
    final members = getParticipants([Membership.ban]);
    if (members.isEmpty) return [];
    return members
      ..sort((small, great) => great.powerLevel.compareTo(small.powerLevel));
  }

  List<User> getCurrentMembers() {
    final members = getParticipants([Membership.invite, Membership.join]);
    if (members.isEmpty) return [];
    return members
      ..sort((small, great) => great.powerLevel.compareTo(small.powerLevel));
  }

  bool canUpdateRoleInRoom(User user) {
    return ownPowerLevel > user.powerLevel && canAssignRoles;
  }

  bool canBanMemberInRoom(User user) {
    return ownPowerLevel > user.powerLevel && canBan;
  }

  Stream get powerLevelsChanged => client.onSync.stream.where(
    (e) =>
        (e.rooms?.join?.containsKey(id) ?? false) &&
        ((e.rooms!.join![id]?.timeline?.events?.any(
                  (s) => s.type == EventTypes.RoomPowerLevels,
                ) ??
                false) ||
            (e.rooms!.join![id]?.timeline?.events?.any(
                  (s) => s.type == EventTypes.RoomMember,
                ) ??
                false)),
  );

  /// Get the default power level for users in the room
  ///
  int getUserDefaultLevel() {
    const usersDefaultKey = 'users_default';

    return getState(
          EventTypes.RoomPowerLevels,
        )?.content.tryGet<int>(usersDefaultKey) ??
        DefaultPowerLevelMember.guest.powerLevel;
  }

  bool get canTransferOwnership {
    return ownPowerLevel >= DefaultPowerLevelMember.owner.powerLevel &&
        canAssignRoles;
  }

  User get ownUser {
    return getParticipants().firstWhere((user) => user.id == client.userID);
  }

  bool get canReportContent => membership.isJoin;

  Map<String, dynamic> getEventContentFromMsgText({
    required String message,
    bool parseMarkdown = true,
    String msgtype = MessageTypes.Text,
  }) {
    final event = <String, dynamic>{'msgtype': msgtype, 'body': message};
    if (parseMarkdown) {
      final html = markdown(
        event['body'],
        getEmotePacks: () => getImagePacksFlat(ImagePackUsage.emoticon),
        getMention: getMention,
      );

      final formatText = event['body']
          .toString()
          .trim()
          .replaceAll(RegExp(r'(<br />)+$'), '')
          .convertLinebreaksToBr('pre')
          .replaceAll(RegExp(r'<br />\n?'), '\n');

      // if the decoded html is the same as the body, there is no need in sending a formatted message
      if (HtmlUnescape().convert(html.replaceAll(RegExp(r'<br />\n?'), '\n')) !=
          formatText) {
        event['format'] = 'org.matrix.custom.html';
        event['formatted_body'] = html;
      }
    }
    return event;
  }
}

extension NullableRoomExtension on Room? {
  bool canSelectToInvite(String? matrixId) {
    if (this == null) return true;
    if (this!.canBan) return true;
    return this!.getBannedMembers().none((u) => u.id == matrixId);
  }
}

extension SortByPowerLevel on List<User> {
  List<User> sortByPowerLevel() {
    final newList = [...this];
    newList.sort((a, b) => b.powerLevel.compareTo(a.powerLevel));
    return newList;
  }
}

extension on String {
  String convertLinebreaksToBr(
    String tagName, {
    bool exclude = false,
    String replaceWith = '<br/>',
  }) {
    final parts = split('$tagName>');
    var convertLinebreaks = exclude;
    for (var i = 0; i < parts.length; i++) {
      if (convertLinebreaks) parts[i] = parts[i].replaceAll('\n', replaceWith);
      convertLinebreaks = !convertLinebreaks;
    }
    return parts.join('$tagName>');
  }
}
