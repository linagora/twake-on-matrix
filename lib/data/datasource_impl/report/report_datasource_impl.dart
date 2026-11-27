import 'package:matrix/matrix.dart';
import 'package:twake_chat/data/datasource/report/report_datasource.dart';
import 'package:twake_chat/domain/exception/report/report_exception.dart';

typedef _SpecVersion = ({int major, int minor});

class ReportDatasourceImpl implements ReportDatasource {
  const ReportDatasourceImpl(this._maybeClient);

  static const _SpecVersion _roomReportSince = (major: 1, minor: 13);
  static const _SpecVersion _userReportSince = (major: 1, minor: 14);
  static final RegExp _specVersionPattern = RegExp(r'^v(\d+)\.(\d+)$');

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
      if (await _isUnsupported(client, exception, _roomReportSince)) {
        throw ReportNotSupportedException(cause: exception);
      }
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
      if (await _isUnsupported(client, exception, _userReportSince)) {
        throw ReportNotSupportedException(cause: exception);
      }
      throw ReportUserFailedException(userId: userId, cause: exception);
    }
  }

  Future<bool> _isUnsupported(
    Client client,
    Exception exception,
    _SpecVersion since,
  ) async {
    if (exception is! MatrixException ||
        exception.error != MatrixError.M_UNRECOGNIZED) {
      return false;
    }
    return !await _advertises(client, since);
  }

  Future<bool> _advertises(Client client, _SpecVersion since) async {
    try {
      final response = await client.getVersions();
      return response.versions.any((version) => _isAtLeast(version, since));
    } on Exception {
      return false;
    }
  }

  bool _isAtLeast(String version, _SpecVersion since) {
    final match = _specVersionPattern.firstMatch(version);
    if (match == null) return false;
    final major = int.parse(match.group(1)!);
    final minor = int.parse(match.group(2)!);
    return major > since.major ||
        (major == since.major && minor >= since.minor);
  }
}
