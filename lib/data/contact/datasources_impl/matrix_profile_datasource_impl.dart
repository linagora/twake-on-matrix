import 'package:matrix/matrix.dart';
import 'package:twake_chat/data/contact/datasources/matrix_profile_datasource.dart';

class MatrixProfileDatasourceImpl implements MatrixProfileDatasource {
  const MatrixProfileDatasourceImpl(this._client);

  final Client? _client;

  @override
  Future<MatrixUserProfile?> fetchProfile(
    String matrixId, {
    bool fresh = false,
  }) async {
    final client = _client;
    if (client == null || matrixId.isEmpty) return null;

    try {
      if (fresh) {
        final profile = await client.getUserProfile(
          matrixId,
          maxCacheAge: Duration.zero,
        );
        return MatrixUserProfile(
          matrixId: matrixId,
          displayName: profile.displayname,
          avatarUrl: profile.avatarUrl?.toString(),
        );
      }
      final profile = await client.getProfileFromUserId(matrixId);
      return MatrixUserProfile(
        matrixId: matrixId,
        displayName: profile.displayName,
        avatarUrl: profile.avatarUrl?.toString(),
      );
    } catch (exception, stackTrace) {
      // Unknown user, offline, rate-limited: the caller keeps its fallback.
      Logs().w(
        'MatrixProfileDatasourceImpl::fetchProfile: $matrixId',
        exception,
        stackTrace,
      );
      return null;
    }
  }
}
