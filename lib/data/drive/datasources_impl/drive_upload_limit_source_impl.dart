import 'package:matrix/matrix.dart' show Client, Logs;
import 'package:twake_chat/domain/drive/sources/drive_upload_limit_source.dart';

/// Reads Matrix's authenticated media config through the room's own client.
/// An unavailable size stays unknown; the upload queue checks the real limit.
class DriveUploadLimitSourceImpl implements DriveUploadLimitSource {
  const DriveUploadLimitSourceImpl(this._client);

  final Client _client;

  @override
  Future<int?> read() async {
    try {
      // The SDK caches this response for three days by default.
      // https://spec.matrix.org/v1.19/client-server-api/#get_matrixclientv1mediaconfig
      return (await _client.getConfig()).mUploadSize;
    } on Exception {
      Logs().w('DriveUploadLimitSourceImpl::read: media config unavailable');
      return null;
    }
  }
}
