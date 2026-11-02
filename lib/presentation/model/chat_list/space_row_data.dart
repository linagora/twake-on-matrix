import 'package:flutter/foundation.dart';
import 'package:twake_chat/presentation/model/chat_list/room_list_row.dart';

/// What the row of a space shows and does beyond a room's.
class SpaceRowData {
  const SpaceRowData({
    required this.fold,
    required this.unreadCount,
    required this.mentionCount,
    required this.onToggleFold,
    this.onAddSubspace,
  });

  final SpaceFold fold;
  final int unreadCount;
  final int mentionCount;
  final VoidCallback onToggleFold;

  /// A sub-space goes under a top space the user may add to.
  final VoidCallback? onAddSubspace;
}
