import 'package:twake_chat/domain/exception/report/report_exception.dart';
import 'package:twake_chat/domain/repository/report/report_repository.dart';

class FakeReportRepository implements ReportRepository {
  FakeReportRepository({this.reportRoomError, this.reportUserError});

  ReportException? reportRoomError;

  ReportException? reportUserError;

  final List<({String roomId, String reason})> roomReports = [];

  final List<({String userId, String reason})> userReports = [];

  @override
  Future<void> reportRoom({
    required String roomId,
    required String reason,
  }) async {
    final error = reportRoomError;
    if (error != null) throw error;
    roomReports.add((roomId: roomId, reason: reason));
  }

  @override
  Future<void> reportUser({
    required String userId,
    required String reason,
  }) async {
    final error = reportUserError;
    if (error != null) throw error;
    userReports.add((userId: userId, reason: reason));
  }
}
