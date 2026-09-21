/// Minimal, SDK-free projection of a Matrix room member.
class MatrixRoomMemberProfile {
  const MatrixRoomMemberProfile({
    required this.matrixId,
    this.displayName,
    this.avatarUrl,
  });

  final String matrixId;
  final String? displayName;
  final String? avatarUrl;
}

/// Reads the members of the joined rooms. The implementation is the only place
/// in this module that imports `package:matrix`.
abstract class MatrixRoomMemberDatasource {
  Future<List<MatrixRoomMemberProfile>> fetchRoomMembers();
}
