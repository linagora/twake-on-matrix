import 'package:collection/collection.dart';
import 'package:fluffychat/config/app_config.dart';
import 'package:fluffychat/domain/model/extensions/string_extension.dart';
import 'package:fluffychat/domain/model/room/room_extension.dart';
import 'package:fluffychat/pages/chat/events/message_reactions.dart';
import 'package:fluffychat/utils/clipboard.dart';
import 'package:fluffychat/utils/dialog/twake_dialog.dart';
import 'package:fluffychat/utils/extension/event_info_extension.dart';
import 'package:fluffychat/utils/extension/mime_type_extension.dart';
import 'package:fluffychat/utils/manager/upload_manager/upload_manager.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions/filtered_timeline_extension.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions/matrix_locals.dart';
import 'package:fluffychat/utils/platform_infos.dart';
import 'package:fluffychat/utils/size_string.dart';
import 'package:fluffychat/utils/string_extension.dart';
import 'package:fluffychat/utils/twake_snackbar.dart';
import 'package:fluffychat/widgets/matrix.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fluffychat/generated/l10n/app_localizations.dart';
import 'package:future_loading_dialog/future_loading_dialog.dart';
import 'package:linagora_design_flutter/colors/linagora_ref_colors.dart';
import 'package:matrix/matrix.dart';
import 'package:universal_html/html.dart' as html;

import 'matrix_file_extension.dart';

extension LocalizedBody on Event {
  Future<LoadingDialogResult<MatrixFile?>> getFile(
    BuildContext context,
  ) async =>
      TwakeDialog.showFutureLoadingDialogFullScreen(
        future: downloadAndDecryptAttachment,
      );

  Future<String?> saveFile(
    BuildContext context, {
    MatrixFile? matrixFile,
  }) async {
    matrixFile ??= (await getFile(context)).result;

    return await matrixFile?.downloadFile(context);
  }

  String get filenameEllipsized {
    return filename.ellipsizeFileName;
  }

  String? get blurHash {
    return infoMap['xyz.amorgan.blurhash'] is String
        ? infoMap['xyz.amorgan.blurhash'] as String
        : null;
  }

  TwakeMimeType? get mimeType {
    return content
        .tryGetMap<String, dynamic>('info')
        ?.tryGet<String>('mimetype');
  }

  String get filename {
    return content.tryGet<String>('filename') ?? body;
  }

  String get thumbnailFilename {
    return 'thumbnail-$filename';
  }

  String? get fileType {
    return (filename.contains('.')
        ? filename.split('.').last.toUpperCase()
        : content
            .tryGetMap<String, dynamic>('info')
            ?.tryGet<String>('mimetype')
            ?.toUpperCase());
  }

  bool get isVideoOrImage =>
      [MessageTypes.Image, MessageTypes.Video].contains(messageType);

  bool get isCopyable => messageType == MessageTypes.Text;

  bool isContains(String? searchTerm) =>
      plaintextBody.toLowerCase().contains(searchTerm?.toLowerCase() ?? '');

  bool get isSearchable =>
      messageType == MessageTypes.Text || messageType == MessageTypes.File;

  String? get firstValidUrl =>
      messageType == MessageTypes.Text ? text.getFirstValidUrl() : null;

  bool get isContainsLink => firstValidUrl != null;

  bool get isAFile => messageType == MessageTypes.File;

  void shareFile(BuildContext context) async {
    final matrixFile = await getFile(context);

    matrixFile.result?.share(context);
  }

  bool get isAttachmentSmallEnough =>
      infoMap['size'] is int &&
      (infoMap['size'] as int) < room.client.database.maxFileSize;

  bool get isThumbnailSmallEnough =>
      thumbnailInfoMap['size'] is int &&
      (thumbnailInfoMap['size'] as int) < room.client.database.maxFileSize;

  bool get showThumbnail =>
      [MessageTypes.Image, MessageTypes.Sticker, MessageTypes.Video]
          .contains(messageType) &&
      (kIsWeb ||
          isAttachmentSmallEnough ||
          isThumbnailSmallEnough ||
          (content['url'] is String));

  Duration? get duration {
    return infoMap['duration'] is int
        ? Duration(milliseconds: infoMap['duration'] as int)
        : null;
  }

  String? get sizeString => content
      .tryGetMap<String, dynamic>('info')
      ?.tryGet<int>('size')
      ?.sizeString;

  MatrixFile? getMatrixFile() {
    final txId = unsigned?['transaction_id'] ?? eventId;
    return room.sendingFilePlaceholders[txId];
  }

  Size? getOriginalResolution() {
    if (infoMap['w'] != null && infoMap['h'] != null) {
      return Size(
        double.tryParse(infoMap['w'].toString()) ?? 0,
        double.tryParse(infoMap['h'].toString()) ?? 0,
      );
    }
    return null;
  }

  User? getUser() {
    return room
        .getParticipants()
        .firstWhereOrNull((user) => user.id == senderId);
  }

  // Check if the sender of the current event is the same as the compared event.
  bool isSameSenderWith(Event? comparedEvent) {
    // If the compared event is null, it is assumed that the message is the newest.
    if (comparedEvent == null) {
      return true;
    }

    final isPreviousOrNextEventMessage = {
      EventTypes.Message,
      EventTypes.Sticker,
      EventTypes.Encrypted,
    }.contains(comparedEvent.type);

    final isPreviousOrNextEventRedacted = {
      RelationshipTypes.edit,
    }.contains(comparedEvent.relationshipType);

    // Ignoring events that are not messages, stickers, encrypted or redaction.
    if (!isPreviousOrNextEventMessage) {
      return true;
    }

    if (isPreviousOrNextEventRedacted) {
      return true;
    }

    return senderId != comparedEvent.senderId;
  }

  bool get isOwnMessage => senderId == room.client.userID;

  bool get shouldAlignOwnMessageInDifferentSide =>
      isOwnMessage && AppConfig.enableRightAndLeftMessageAlignmentOnWeb;

  bool get shouldDisplayContextMenuInLeftBubble {
    return AppConfig.enableRightAndLeftMessageAlignmentOnWeb
        ? _isContextMenuForLeftAlignedMessage()
        : false;
  }

  bool get shouldDisplayContextMenuInRightBubble {
    return AppConfig.enableRightAndLeftMessageAlignmentOnWeb
        ? _isContextMenuForRightAlignedMessage()
        : true;
  }

  bool _isContextMenuForLeftAlignedMessage() => isOwnMessage;

  bool _isContextMenuForRightAlignedMessage() => !isOwnMessage;

  bool get timelineOverlayMessage =>
      {
        MessageTypes.Video,
        MessageTypes.Image,
      }.contains(messageType) &&
      isVideoAvailable &&
      !isCaptionModeOrReply();

  bool get hideDisplayNameInBubbleChat => {
        MessageTypes.Video,
        MessageTypes.Image,
        MessageTypes.File,
      }.contains(messageType);

  bool hideDisplayName(Event? nextEvent, bool isMobile) =>
      isMobile && (isOwnMessage || room.isDirectChat) ||
      !isSameSenderWith(nextEvent) ||
      (isOwnMessage && redacted) ||
      type == EventTypes.Encrypted ||
      shouldAlignOwnMessageInDifferentSide;

  bool get isPinned => room.pinnedEventIds.contains(eventId);

  Future<void> copy(BuildContext context, Timeline timeline) async {
    if (messageType == MessageTypes.Image && PlatformInfos.isWeb) {
      final matrixFile = getMatrixFile() ??
          await downloadAndDecryptAttachment(
            getThumbnail: true,
          );
      try {
        await TwakeClipboard.instance.copyImageAsBytes(
          matrixFile.bytes,
          mimeType: mimeType,
        );
      } catch (e) {
        TwakeSnackBar.show(context, L10n.of(context)!.copyImageFailed);
        Logs().e(
          'copySingleEventAction(): failed to copy file ${matrixFile.name}',
        );
      }
    } else {
      copyTextEvent(context, timeline);
    }
  }

  Future<void> copyTextEvent(BuildContext context, Timeline timeline) async {
    await TwakeClipboard.instance
        .copyText(getSelectedEventString(context, timeline));
    TwakeSnackBar.show(
      context,
      L10n.of(context)!.textCopiedToClipboard,
    );
  }

  String getSelectedEventString(BuildContext context, Timeline timeline) {
    if (isCaptionModeOrReply()) {
      return body;
    }
    return getDisplayEventWithoutEditEvent(timeline).calcLocalizedBodyFallback(
      MatrixLocals(L10n.of(context)!),
      hideReply: true,
    );
  }

  bool isBubbleEventEncrypted({bool isThumbnail = true}) {
    if (isThumbnail) {
      return hasThumbnail ? isThumbnailEncrypted : isAttachmentEncrypted;
    }
    return isAttachmentEncrypted;
  }

  bool isDisplayOnlyEmoji() {
    return onlyEmotes && numberEmotes > 0 && numberEmotes < 7;
  }

  TextStyle? textStyleForOnlyEmoji(BuildContext context) {
    switch (numberEmotes) {
      case 1:
        return Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontSize: 79.5,
              color: Theme.of(context).colorScheme.onSurface,
            );
      case 2:
        return Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontSize: 63.24,
              color: Theme.of(context).colorScheme.onSurface,
            );
      case 3:
        return Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontSize: 54.2,
              color: Theme.of(context).colorScheme.onSurface,
            );
      case 4:
        return Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontSize: 45.17,
              color: Theme.of(context).colorScheme.onSurface,
            );
      case 5:
        return Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontSize: 36.14,
              color: Theme.of(context).colorScheme.onSurface,
            );
      case 6:
        return Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontSize: 18.07,
              color: Theme.of(context).colorScheme.onSurface,
            );
      default:
        return Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
            );
    }
  }

  TextStyle? getMessageTextStyle(BuildContext context) {
    if (redacted) {
      return Theme.of(context).textTheme.bodyLarge?.copyWith(
            fontSize: 17,
            height: 24 / 17,
            color: LinagoraRefColors.material().tertiary[30],
          );
    }

    if (isDisplayOnlyEmoji()) {
      return textStyleForOnlyEmoji(context);
    }

    return Theme.of(context).textTheme.bodyLarge?.copyWith(
          color: Theme.of(
            context,
          ).colorScheme.onSurface,
        );
  }

  List<Client?> currentRoomBundle(MatrixState? matrix) {
    if (matrix == null || matrix.currentBundle == null) {
      return [];
    }
    final clients = matrix.currentBundle!;
    clients.removeWhere((c) => c!.getRoomById(roomId!) == null);
    return clients;
  }

  bool isBadEncryptedEvent() {
    return room.encrypted &&
        (type == EventTypes.Encrypted &&
            messageType == MessageTypes.BadEncrypted);
  }

  bool canEditEvents(MatrixState? matrix) {
    if (isCaptionModeOrReply()) {
      return true;
    }

    if (isVideoOrImage || hasAttachment) {
      return false;
    }

    if (!room.canSendDefaultMessages) {
      return false;
    }

    if (isBadEncryptedEvent()) {
      return false;
    }

    return currentRoomBundle(matrix).any((cl) => senderId == cl!.userID);
  }

  bool get canDelete {
    if (isOwnMessage) {
      return room.canSendRedactEvent;
    }
    return room.canRedactEventSentByOther;
  }

  bool shouldHideRedactedEvent() {
    return AppConfig.hideRedactedEvents &&
        (redacted || type == EventTypes.Redaction);
  }

  bool shouldHideBannedEvent() {
    return type == EventTypes.RoomMember && content['membership'] == 'ban';
  }

  bool shouldHideChangedAvatarEvent() {
    return isSomeoneChangeAvatar();
  }

  bool shouldHideChangedDisplayNameEvent() {
    return isSomeoneChangeDisplayName();
  }

  bool hasReactionEvent({
    required Timeline timeline,
  }) {
    final allReactionEvents =
        aggregatedEvents(timeline, RelationshipTypes.reaction);
    final reactionMap = <String, ReactionEntry>{};

    for (final e in allReactionEvents) {
      final key = e.content
          .tryGetMap<String, dynamic>('m.relates_to')
          ?.tryGet<String>('key');
      if (key != null) {
        if (!reactionMap.containsKey(key)) {
          reactionMap[key] = ReactionEntry(
            key: key,
            count: 0,
            reacted: false,
            reactors: [],
          );
        }
        reactionMap[key]!.count++;
        reactionMap[key]!.reactors!.add(e.senderFromMemoryOrFallback);
        reactionMap[key]!.reacted |= e.senderId == e.room.client.userID;
      }
    }

    return reactionMap.isNotEmpty;
  }

  /// Checks if this event should be handled in caption mode.
  /// Returns true when:
  /// - Media/file events (image, video, file) with non-empty text that differs from filename, OR
  /// - Any reply event (to enable caption input when replying with media)
  ///
  /// This affects editing, copying, and UI rendering behavior across the app.
  bool isCaptionModeOrReply() {
    return ((messageType == MessageTypes.Image ||
                messageType == MessageTypes.Video ||
                messageType == MessageTypes.File) &&
            text.isNotEmpty &&
            isBodyDiffersFromFilename()) ||
        isReplyEvent();
  }

  /// Returns true if the event's body text differs from its filename.
  /// Used to determine if a caption should be displayed for media files.
  bool isBodyDiffersFromFilename() {
    return content["body"] != content["filename"];
  }

  /// Returns true if this event is a reply to another event.
  bool isReplyEvent() {
    return inReplyToEventId() != null;
  }

  bool isReplyEventWithAudio() {
    return isReplyEvent() && messageType == MessageTypes.Audio;
  }

  /// Checks if this event is the same as another event, considering both eventId and transaction_id.
  /// Returns true if events match by eventId or by transaction_id (for sending/sent events).
  bool isSameEvent(Event other) {
    // Compare event IDs
    if (eventId == other.eventId) {
      return true;
    }

    // Get transaction IDs from unsigned field
    final thisTransactionId = unsigned?['transaction_id'] as String?;
    final otherTransactionId = other.unsigned?['transaction_id'] as String?;

    // If both have transaction IDs, compare them
    if (thisTransactionId != null && otherTransactionId != null) {
      return thisTransactionId == otherTransactionId;
    }

    // Check if one event's eventId matches the other's transaction_id
    // This handles the case where a sending event (with transaction_id) is replaced
    // by a sent event (with eventId matching the transaction_id)
    if (thisTransactionId != null && thisTransactionId == other.eventId) {
      return true;
    }
    if (otherTransactionId != null && otherTransactionId == eventId) {
      return true;
    }

    return false;
  }

  /// Finds this event in the map using the same logic as isSameEvent.
  Event? findEventInMap(Map<String, Event> eventMap) {
    // Try to find by eventId
    final byEventId = eventMap[eventId];
    if (byEventId != null) return byEventId;

    // Try to find by transactionId
    final transactionId = unsigned?['transaction_id'] as String?;
    if (transactionId != null) {
      final byTransactionId = eventMap[transactionId];
      if (byTransactionId != null) return byTransactionId;
    }

    return null;
  }

  Event getDisplayEventWithoutEditEvent(Timeline timeline) {
    if (redacted) {
      return this;
    }

    if (!hasAggregatedEvents(timeline, RelationshipTypes.edit)) {
      return this;
    }

    // Get all valid edit events from the original author
    final editEvents = aggregatedEvents(timeline, RelationshipTypes.edit)
        .where((e) => e.senderId == senderId && e.type == EventTypes.Message)
        .toList();

    if (editEvents.isEmpty) {
      return this;
    }

    // Find the most recent edit event
    final latestEdit = editEvents.reduce(
      (latest, current) => current.originServerTs.millisecondsSinceEpoch >
              latest.originServerTs.millisecondsSinceEpoch
          ? current
          : latest,
    );

    final editEventJson = latestEdit.toJson();
    final newContent = editEventJson['content']['m.new_content'];

    if (newContent is! Map) {
      return this;
    }

    if (isCaptionModeOrReply()) {
      // For media/files with caption, preserve original event structure
      // and add the edited content
      final originalEventJson = toJson();
      originalEventJson['content']['m.new_content'] = newContent;
      originalEventJson['content']['body'] = newContent['body'];

      // Update formatted_body if it exists in the new content
      if (newContent['formatted_body'] != null) {
        originalEventJson['content']['formatted_body'] =
            newContent['formatted_body'];
        originalEventJson['content']['format'] = newContent['format'];
      } else {
        originalEventJson['content'].remove('formatted_body');
        originalEventJson['content'].remove('format');
      }

      return Event.fromJson(originalEventJson, room);
    }

    // For regular text messages, use the edited event structure
    editEventJson['content'] = newContent;
    return Event.fromJson(editEventJson, room);
  }

  bool get isMention {
    final currentUserId = room.client.userID;
    if (currentUserId == null) return false;

    final formattedBody = content.tryGet<String>('formatted_body');
    if (formattedBody == null || formattedBody.isEmpty) return false;

    try {
      final document =
          html.DomParser().parseFromString(formattedBody, 'text/html');
      final anchors = document.querySelectorAll('a');

      for (final anchor in anchors) {
        final href = anchor.attributes['href'];
        if (href == null || href.isEmpty) continue;

        final matrixToIndex = href.indexOf('matrix.to/#/');
        if (matrixToIndex == -1) continue;

        final idStart = matrixToIndex + 'matrix.to/#/'.length;
        if (idStart >= href.length) continue;

        var idEnd = href.indexOf('?', idStart);
        if (idEnd == -1) idEnd = href.length;

        final encodedId = href.substring(idStart, idEnd);

        try {
          final decodedId = Uri.decodeComponent(encodedId);
          // Early exit as soon as we find the current user
          if (decodedId == currentUserId && decodedId.isValidMatrixId) {
            return true;
          }
        } catch (e) {
          continue;
        }
      }
    } catch (e) {
      Logs().e('Error parsing HTML for mention check', e);
    }

    return false;
  }

  bool isFileStoreable({bool getThumbnail = false}) {
    final database = room.client.database;
    final thisInfoMap = getThumbnail ? thumbnailInfoMap : infoMap;
    return thisInfoMap['size'] is int &&
        (thisInfoMap['size'] as int) <= database.maxFileSize;
  }
}

extension FutureEventExtension on Event {
  Future<String> calcLocalizedBodyRemoveBreakLine(L10n l10n) async {
    final body = await calcLocalizedBody(
      MatrixLocals(l10n),
      hideReply: true,
      hideEdit: true,
      plaintextBody: true,
      removeMarkdown: true,
    );

    return body.replaceAll(RegExp(r'\n'), ' ');
  }

  String calcLocalizedBodyFallbackRemoveBreakLine(L10n l10n) {
    final body = calcLocalizedBodyFallback(
      MatrixLocals(l10n),
      hideReply: true,
      hideEdit: true,
      plaintextBody: true,
      removeMarkdown: true,
    );

    return body.replaceAll(RegExp(r'\n'), ' ');
  }

  Future<MatrixFile?> getPlaceholderMatrixFile(
    UploadManager uploadManager,
  ) async {
    final placeholder = getMatrixFile();
    if (placeholder != null) {
      return placeholder;
    }
    return await uploadManager.getMatrixFile(
      eventId,
      room: room,
    );
  }
}
