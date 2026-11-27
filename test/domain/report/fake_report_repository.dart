import 'package:twake_chat/domain/exception/report/report_exception.dart';
import 'package:twake_chat/domain/repository/report/report_repository.dart';

class FakeReportRepository implements ReportRepository {
  FakeReportRepository({this.reportRoomError});

  ReportException? reportRoomError;

  final List<({String roomId, String reason})> roomReports = [];

  @override
  Future<void> reportRoom({
    required String roomId,
    required String reason,
  }) async {
    final error = reportRoomError;
    if (error != null) throw error;
    roomReports.add((roomId: roomId, reason: reason));
  }
}
