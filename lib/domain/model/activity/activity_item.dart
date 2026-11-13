import 'package:equatable/equatable.dart';

/// What an item of the Activity tab tells (THR-M-12).
enum ActivityKind { unreadRoom, mention, reply, reaction }

/// One line of the Activity tab: [authorName] did something in [roomName]
/// at [time]. [quote] is the message the line shows.
class ActivityItem extends Equatable {
  const ActivityItem({
    required this.kind,
    required this.roomId,
    required this.roomName,
    required this.time,
    required this.authorName,
    this.authorAvatarUrl,
    this.quote,
    this.unreadCount = 0,
    this.eventId,
    this.threadRootId,
    this.threadTitle,
    this.isResolved = false,
    this.emoji,
  });

  final ActivityKind kind;
  final String roomId;
  final String roomName;
  final DateTime time;

  /// Empty when the room has no message to name an author of.
  final String authorName;
  final Uri? authorAvatarUrl;
  final String? quote;
  final int unreadCount;

  /// The message the item is about; the last reply for a followed thread.
  final String? eventId;

  /// The root of the thread the item is in, if any.
  final String? threadRootId;

  /// The start of the root of the thread.
  final String? threadTitle;
  final bool isResolved;
  final String? emoji;

  @override
  List<Object?> get props => [
    kind,
    roomId,
    roomName,
    time,
    authorName,
    authorAvatarUrl,
    quote,
    unreadCount,
    eventId,
    threadRootId,
    threadTitle,
    isResolved,
    emoji,
  ];
}
