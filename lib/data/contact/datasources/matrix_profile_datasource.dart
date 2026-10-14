/// SDK-free projection of a Matrix user profile.
class MatrixUserProfile {
  const MatrixUserProfile({
    required this.matrixId,
    this.displayName,
    this.avatarUrl,
  });

  final String matrixId;
  final String? displayName;
  final String? avatarUrl;
}

/// Reads a user profile from the Matrix SDK. The implementation is the only
/// place that imports `package:matrix`; it receives the `Client` from the
/// `activeMatrixClientProvider` (Riverpod owns the access).
abstract class MatrixProfileDatasource {
  Future<MatrixUserProfile?> fetchProfile(String matrixId);
}
