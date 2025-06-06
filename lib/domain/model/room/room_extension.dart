import 'package:fluffychat/domain/model/search/recent_chat_model.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions/client_stories_extension.dart';
import 'package:matrix/matrix.dart';

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
    return [
      EventTypes.Message,
      EventTypes.Sticker,
      EventTypes.Encrypted,
    ].contains(lastEvent?.type);
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

  String storePlaceholderFileInMem({
    required FileInfo fileInfo,
    String? txid,
  }) {
    txid ??= client.generateUniqueTransactionId();
    final matrixFile = MatrixFile.fromFileInfo(
      fileInfo: fileInfo,
    );
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
            getDefaultPowerLevel(currentPowerLevelsMap)) <=
        ownPowerLevel;
  }

  bool get canChangeTopic {
    final currentPowerLevelsMap = getState(EventTypes.RoomPowerLevels)?.content;
    if (currentPowerLevelsMap == null) return 0 <= ownPowerLevel;
    return (currentPowerLevelsMap
                .tryGetMap<String, Object?>('events')
                ?.tryGet<int>(EventTypes.RoomTopic) ??
            getDefaultPowerLevel(currentPowerLevelsMap)) <=
        ownPowerLevel;
  }

  bool get canChangeRoomAvatar {
    final currentPowerLevelsMap = getState(EventTypes.RoomPowerLevels)?.content;
    if (currentPowerLevelsMap == null) return 0 <= ownPowerLevel;
    return (currentPowerLevelsMap
                .tryGetMap<String, Object?>('events')
                ?.tryGet<int>(EventTypes.RoomAvatar) ??
            getDefaultPowerLevel(currentPowerLevelsMap)) <=
        ownPowerLevel;
  }

  bool get canEnableEncryption {
    final currentPowerLevelsMap = getState(EventTypes.RoomPowerLevels)?.content;
    if (currentPowerLevelsMap == null) return 0 <= ownPowerLevel;
    return (currentPowerLevelsMap
                .tryGetMap<String, Object?>('events')
                ?.tryGet<int>(EventTypes.Encryption) ??
            getDefaultPowerLevel(currentPowerLevelsMap)) <=
        ownPowerLevel;
  }

  bool get isRoomPublic {
    return joinRules == JoinRules.public;
  }

  bool get canEditChatDetails {
    return canChangeRoomName ||
        canChangeTopic ||
        canChangeRoomAvatar ||
        canEnableEncryption ||
        canChangePowerLevel;
  }
}
