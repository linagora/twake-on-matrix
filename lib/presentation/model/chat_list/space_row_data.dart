import 'package:flutter/foundation.dart';
import 'package:twake_chat/presentation/model/chat_list/room_list_row.dart';

/// What the row of a space shows and does beyond a room's.
class SpaceRowData {
  const SpaceRowData({
    required this.fold,
    required this.roomCount,
    required this.unreadCount,
    required this.mentionCount,
    required this.onToggleFold,
  });

  final SpaceFold fold;
  final int roomCount;
  final int unreadCount;
  final int mentionCount;
  final VoidCallback onToggleFold;
}
