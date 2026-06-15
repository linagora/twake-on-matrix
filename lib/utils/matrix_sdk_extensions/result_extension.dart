import 'package:fluffychat/utils/matrix_sdk_extensions/matrix_event_fields.dart';
import 'package:fluffychat/widgets/matrix.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';

extension ResultExtension on Result {
  Event? getEvent(BuildContext? context) {
    if (context == null) {
      return null;
    }
    if (result?.roomId == null) {
      return null;
    }
    final room = Matrix.of(context).client.getRoomById(result!.roomId!);
    if (room == null) {
      return null;
    }
    final event = Event.fromMatrixEvent(result!, room);
    return _resolveEditedContent(event);
  }

  /// Resolves the latest edited content from `unsigned.m.relations.m.replace`
  /// if present. The Matrix search API returns original events, not their
  /// edited versions, so we must apply the edit ourselves since there is no
  /// timeline available.
  ///
  /// Synapse stores the edit event under unsigned.m.relations.m.replace as:
  /// `{ "content": { "m.new_content": { ... } }, ... }`
  Event _resolveEditedContent(Event event) {
    final relations = event.unsigned?.tryGetMap<String, Object?>(
      MatrixEventFields.relations,
    );
    if (relations == null) return event;

    // unsigned.m.relations.m.replace is the latest edit event object
    final latestEditEvent = relations.tryGetMap<String, Object?>(
      RelationshipTypes.edit,
    );
    if (latestEditEvent == null) return event;

    // m.new_content is nested inside the edit event's content field
    final editContent = latestEditEvent.tryGetMap<String, Object?>(
      MatrixEventFields.content,
    );
    if (editContent == null) return event;

    final newContent = editContent.tryGetMap<String, Object?>(
      MatrixEventFields.newContent,
    );
    if (newContent == null) return event;

    final rawEvent = event.toJson();
    rawEvent[MatrixEventFields.content] = newContent;
    return Event.fromJson(rawEvent, event.room);
  }

  bool isDisplayableResult({
    BuildContext? context,
    Event? event,
    required String searchWord,
    required MatrixLocalizations matrixLocalizations,
  }) {
    if (context == null) {
      return false;
    }
    if (event == null) {
      return false;
    }
    // Exclude edit events (m.replace) — the server returns both the original
    // and the edit event; showing edit events causes duplicate results.
    if (event.relationshipType == RelationshipTypes.edit) {
      return false;
    }
    final bodyContent = event.calcLocalizedBodyFallback(
      matrixLocalizations,
      hideEdit: true,
      hideReply: true,
      plaintextBody: true,
      removeMarkdown: true,
    );

    // Strip VS16 (U+FE0F) so searching ❤️ matches ❤ and vice versa.
    const vs16 = '\uFE0F';
    return bodyContent
        .replaceAll(vs16, '')
        .toLowerCase()
        .contains(searchWord.replaceAll(vs16, '').toLowerCase());
  }
}
