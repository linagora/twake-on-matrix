import 'package:collection/collection.dart';
import 'package:matrix/matrix.dart';
import 'package:twake_chat/domain/model/thread/thread_relation_extension.dart';

abstract final class ThreadRules {
  static bool canStartThread(
    Event event, {
    required bool hasThread,
    bool inThreadScreen = false,
  }) =>
      !hasThread &&
      !inThreadScreen &&
      event.room.canSendDefaultMessages &&
      event.type != EventTypes.Encrypted &&
      event.threadRootId == null;

  /// The event every main-timeline receipt targets: Synapse refuses a `main`
  /// receipt on a thread event or an event related to one (edit, reaction).
  static Event? newestMainTimelineEvent(Iterable<Event> eventsNewestFirst) =>
      eventsNewestFirst.firstWhereOrNull(
        (e) =>
            e.status.isSynced &&
            e.threadRootId == null &&
            e.type != EventTypes.Redaction &&
            e.relationshipType != RelationshipTypes.edit &&
            e.relationshipType != RelationshipTypes.reaction,
      );
}
