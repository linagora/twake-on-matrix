import 'package:matrix/matrix.dart';
import 'package:twake_chat/data/contact/datasources/matrix_profile_datasource.dart';

class MatrixProfileDatasourceImpl implements MatrixProfileDatasource {
  const MatrixProfileDatasourceImpl(this._client);

  final Client? _client;

  @override
  Future<MatrixUserProfile?> fetchProfile(String matrixId) async {
    final client = _client;
    if (client == null || matrixId.isEmpty) return null;

    try {
      final profile = await client.getProfileFromUserId(
        matrixId,
        getFromRooms: false,
      );
      return MatrixUserProfile(
        matrixId: matrixId,
        displayName: profile.displayName,
        avatarUrl: profile.avatarUrl?.toString(),
      );
    } catch (_) {
      return null;
    }
  }
}
