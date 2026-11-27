import 'package:matrix/matrix.dart';
import 'package:twake_chat/data/datasource/report/report_datasource.dart';
import 'package:twake_chat/domain/exception/report/report_exception.dart';

class ReportDatasourceImpl implements ReportDatasource {
  const ReportDatasourceImpl(this._maybeClient);

  final Client? _maybeClient;

  Client get _client => _maybeClient ?? (throw const ReportNoClientException());

  @override
  Future<void> reportRoom({
    required String roomId,
    required String reason,
  }) async {
    final client = _client;
    try {
      await client.reportRoom(roomId, reason);
    } on Exception catch (exception, stackTrace) {
      Logs().e('ReportDatasourceImpl::reportRoom', exception, stackTrace);
      throw ReportRoomFailedException(roomId: roomId, cause: exception);
    }
  }

  @override
  Future<void> reportUser({
    required String userId,
    required String reason,
  }) async {
    final client = _client;
    try {
      await client.reportUser(userId, reason);
    } on Exception catch (exception, stackTrace) {
      Logs().e('ReportDatasourceImpl::reportUser', exception, stackTrace);
      throw ReportUserFailedException(userId: userId, cause: exception);
    }
  }
}
