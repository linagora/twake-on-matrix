import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/domain/exception/report/report_exception.dart';
import 'package:twake_chat/domain/report/usecases/report_user_usecase.dart';

import '../fake_report_repository.dart';

void main() {
  test('execute_whenTheServerAccepts_reportsTheUserWithTheReason', () async {
    final repository = FakeReportRepository();

    await ReportUserUseCase(
      repository,
    ).execute(userId: '@bob:hs', reason: 'Other: rude');

    expect(repository.userReports, [
      (userId: '@bob:hs', reason: 'Other: rude'),
    ]);
    expect(repository.roomReports, isEmpty);
  });

  test('execute_whenTheReportFails_throwsReportUserFailed', () async {
    final repository = FakeReportRepository(
      reportUserError: ReportUserFailedException(
        userId: '@bob:hs',
        cause: Exception('forbidden'),
      ),
    );

    final result = ReportUserUseCase(
      repository,
    ).execute(userId: '@bob:hs', reason: 'Spam');

    await expectLater(result, throwsA(isA<ReportUserFailedException>()));
  });
}
