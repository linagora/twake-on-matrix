import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/domain/exception/report/report_exception.dart';
import 'package:twake_chat/domain/report/usecases/report_room_usecase.dart';

import '../fake_report_repository.dart';

void main() {
  test('execute_whenTheServerAccepts_reportsTheRoomWithTheReason', () async {
    final repository = FakeReportRepository();

    await ReportRoomUseCase(
      repository,
    ).execute(roomId: '!room:hs', reason: 'Other: rude');

    expect(repository.roomReports, [
      (roomId: '!room:hs', reason: 'Other: rude'),
    ]);
  });

  test('execute_whenTheReportFails_throwsReportRoomFailed', () async {
    final repository = FakeReportRepository(
      reportRoomError: ReportRoomFailedException(
        roomId: '!room:hs',
        cause: Exception('forbidden'),
      ),
    );

    final result = ReportRoomUseCase(
      repository,
    ).execute(roomId: '!room:hs', reason: 'Spam');

    await expectLater(result, throwsA(isA<ReportRoomFailedException>()));
  });
}
