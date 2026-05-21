/// Matrix spec field name constants for event content and unsigned data.
///
/// Follows the same pattern as [RelationshipTypes] in the Matrix SDK.
abstract class MatrixEventFields {
  /// Key for the relations map inside `unsigned` data.
  ///
  /// Synapse places the latest edit under `unsigned['m.relations']['m.replace']`.
  static const String relations = 'm.relations';

  /// Key for the event content map in raw JSON.
  static const String content = 'content';

  /// Key for the new content inside an edit event's `content`.
  ///
  /// Edit events carry the replacement body under `content['m.new_content']`.
  static const String newContent = 'm.new_content';
}
