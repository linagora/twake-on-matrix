import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:twake_chat/domain/model/thread/thread_prefs.dart';

part 'thread_status.freezed.dart';

/// What the menu of a thread shows, read from the account.
@freezed
abstract class ThreadStatus with _$ThreadStatus {
  const factory ThreadStatus({
    required ThreadFollow follow,
    required bool isResolved,

    /// The user may set the resolved state of the room.
    required bool canResolve,
  }) = _ThreadStatus;
}
