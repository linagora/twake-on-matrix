import 'package:async/async.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';

mixin MarkReadMixin {
  RestartableTimer? _checkUnreadTimer;
  RestartableTimer? _markReadTimer;
  FocusNode? _chatFocusNode;

  /// The [getRoomCallback] is evaluated dynamically on
  /// each sync update, so it works even if the room is null during initialization.
  void initMarkRead({
    required BuildContext context,
    required Room? Function() getRoomCallback,
    required FocusNode chatFocusNode,
  }) {
    _checkUnreadTimer = RestartableTimer(
      const Duration(seconds: 2),
      () {
        final room = getRoomCallback();
        if (room != null && room.hasNewMessages) {
          _markReadTimer?.reset();
        }
        _checkUnreadTimer?.reset();
      },
    );
    _markReadTimer = RestartableTimer(
      const Duration(milliseconds: 500),
      () {
        final room = getRoomCallback();
        if (room == null) return;
        final lastEventId = room.lastEvent?.eventId;
        if (lastEventId == null) return;
        room.setReadMarker(lastEventId, mRead: lastEventId);
      },
    )..cancel();
    _chatFocusNode = chatFocusNode;
    _chatFocusNode?.addListener(_focusListener);
  }

  void disposeMarkRead() {
    _chatFocusNode?.removeListener(_focusListener);
    _markReadTimer?.cancel();
    _checkUnreadTimer?.cancel();
  }

  void _focusListener() {
    if (_chatFocusNode?.hasFocus == true) {
      _checkUnreadTimer?.reset();
    } else {
      _checkUnreadTimer?.cancel();
    }
  }
}
