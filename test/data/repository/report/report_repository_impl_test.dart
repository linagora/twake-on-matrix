import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/data/datasource/report/report_datasource.dart';
import 'package:twake_chat/data/repository/report/report_repository_impl.dart';
import 'package:twake_chat/domain/exception/report/report_exception.dart';

class _FakeReportDatasource implements ReportDatasource {
  _FakeReportDatasource({this.error});

  final ReportException? error;

  final List<({String roomId, String reason})> roomReports = [];

  @override
  Future<void> reportRoom({
    required String roomId,
    required String reason,
  }) async {
    final error = this.error;
    if (error != null) throw error;
    roomReports.add((roomId: roomId, reason: reason));
  }
}

void main() {
  test(
    'reportRoom_whenTheDatasourceSucceeds_forwardsRoomIdAndReason',
    () async {
      final datasource = _FakeReportDatasource();

      await ReportRepositoryImpl(
        datasource,
      ).reportRoom(roomId: '!room:hs', reason: 'Spam');

      expect(datasource.roomReports, [(roomId: '!room:hs', reason: 'Spam')]);
    },
  );

  test('reportRoom_whenTheDatasourceFails_keepsTheExceptionType', () async {
    final datasource = _FakeReportDatasource(
      error: ReportRoomFailedException(
        roomId: '!room:hs',
        cause: Exception('forbidden'),
      ),
    );

    final result = ReportRepositoryImpl(
      datasource,
    ).reportRoom(roomId: '!room:hs', reason: 'Spam');

    await expectLater(result, throwsA(isA<ReportRoomFailedException>()));
  });
}
