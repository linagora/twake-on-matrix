import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/data/datasource/report/report_datasource.dart';
import 'package:twake_chat/data/repository/report/report_repository_impl.dart';
import 'package:twake_chat/domain/exception/report/report_exception.dart';

class _FakeReportDatasource implements ReportDatasource {
  _FakeReportDatasource({this.error});

  final ReportException? error;

  final List<({String roomId, String reason})> roomReports = [];

  final List<({String userId, String reason})> userReports = [];

  @override
  Future<void> reportRoom({
    required String roomId,
    required String reason,
  }) async {
    final error = this.error;
    if (error != null) throw error;
    roomReports.add((roomId: roomId, reason: reason));
  }

  @override
  Future<void> reportUser({
    required String userId,
    required String reason,
  }) async {
    final error = this.error;
    if (error != null) throw error;
    userReports.add((userId: userId, reason: reason));
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

  test(
    'reportUser_whenTheDatasourceSucceeds_forwardsUserIdAndReason',
    () async {
      final datasource = _FakeReportDatasource();

      await ReportRepositoryImpl(
        datasource,
      ).reportUser(userId: '@bob:hs', reason: 'Spam');

      expect(datasource.userReports, [(userId: '@bob:hs', reason: 'Spam')]);
    },
  );

  test('reportUser_whenTheDatasourceFails_keepsTheExceptionType', () async {
    final datasource = _FakeReportDatasource(
      error: ReportUserFailedException(
        userId: '@bob:hs',
        cause: Exception('forbidden'),
      ),
    );

    final result = ReportRepositoryImpl(
      datasource,
    ).reportUser(userId: '@bob:hs', reason: 'Spam');

    await expectLater(result, throwsA(isA<ReportUserFailedException>()));
  });
}
