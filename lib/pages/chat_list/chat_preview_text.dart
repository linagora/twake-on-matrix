import 'package:fluffychat/domain/model/room/room_preview_result.dart';
import 'package:fluffychat/generated/l10n/app_localizations.dart';
import 'package:fluffychat/pages/chat_list/chat_list_skeletonizer_style.dart';
import 'package:flutter/material.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';
import 'package:skeletonizer/skeletonizer.dart';

class ChatPreviewText extends StatelessWidget {
  final RoomPreviewResult? previewResult;
  final TextStyle? style;
  final L10n l10n;

  const ChatPreviewText({
    super.key,
    required this.previewResult,
    required this.style,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    return switch (previewResult) {
      null => Skeletonizer(
        enabled: true,
        child: Text(
          ChatListSkeletonizerStyle.subtitleHardCode,
          style: style,
          softWrap: false,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      RoomPreviewUnavailable() => Text(
        l10n.chatPreviewUnavailable,
        style: ListItemStyle.subtitleTextStyle(
          fontFamily: 'Inter',
        ).copyWith(fontStyle: FontStyle.italic),
        softWrap: false,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      RoomPreviewEmpty() || RoomPreviewFound() => Text(
        l10n.thisIsANewChat,
        style: ListItemStyle.subtitleTextStyle(
          fontFamily: 'Inter',
        ).copyWith(fontStyle: FontStyle.italic),
        softWrap: false,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    };
  }
}
