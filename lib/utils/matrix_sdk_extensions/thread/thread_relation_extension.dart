import 'package:matrix/matrix.dart';

extension ThreadRelationExtension on MatrixEvent {
  /// Id of the thread root when this event is a reply of a thread, read from
  /// `m.relates_to` (kept in clear even on encrypted events).
  String? get threadRootId {
    final relatesTo = content.tryGetMap<String, Object?>('m.relates_to');
    if (relatesTo?.tryGet<String>('rel_type') != RelationshipTypes.thread) {
      return null;
    }
    return relatesTo?.tryGet<String>('event_id');
  }

  /// True for the root of the thread [rootId] and for its replies.
  bool isInThread(String rootId) => eventId == rootId || threadRootId == rootId;
}
