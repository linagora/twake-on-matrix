import 'package:twake_chat/domain/contact/sources/contact_source.dart';

/// Reads the members of the joined rooms. The implementation is the only place
/// in this module that imports `package:matrix`.
abstract class MatrixRoomMemberDatasource {
  /// Members visible to the account identified by [userId].
  ///
  /// Implementations must throw when [userId] is not the account they are
  /// bound to: returning another account's members would corrupt the store of
  /// the account being synced.
  Future<List<SourcedContact>> fetchRoomMembers(String userId);
}
