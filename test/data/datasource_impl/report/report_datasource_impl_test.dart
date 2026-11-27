import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:twake_chat/data/datasource_impl/report/report_datasource_impl.dart';
import 'package:twake_chat/domain/exception/report/report_exception.dart';

import 'report_datasource_impl_test.mocks.dart';

@GenerateNiceMocks([MockSpec<Client>()])
void main() {
  late MockClient client;

  setUp(() {
    client = MockClient();
  });

  test('reportRoom_whenTheServerAccepts_sendsTheRoomIdAndReason', () async {
    when(client.reportRoom(any, any)).thenAnswer((_) async {});

    await ReportDatasourceImpl(
      client,
    ).reportRoom(roomId: '!room:hs', reason: 'Spam');

    verify(client.reportRoom('!room:hs', 'Spam')).called(1);
  });

  test('reportRoom_whenTheServerFails_throwsReportRoomFailed', () async {
    when(
      client.reportRoom(any, any),
    ).thenThrow(MatrixException.fromJson({'errcode': 'M_FORBIDDEN'}));

    final result = ReportDatasourceImpl(
      client,
    ).reportRoom(roomId: '!room:hs', reason: 'Spam');

    await expectLater(
      result,
      throwsA(
        isA<ReportRoomFailedException>().having(
          (exception) => exception.roomId,
          'roomId',
          '!room:hs',
        ),
      ),
    );
  });

  test('reportRoom_whenNobodyIsSignedIn_throwsReportNoClient', () async {
    final result = const ReportDatasourceImpl(
      null,
    ).reportRoom(roomId: '!room:hs', reason: 'Spam');

    await expectLater(result, throwsA(isA<ReportNoClientException>()));
  });

  test('reportUser_whenTheServerAccepts_sendsTheUserIdAndReason', () async {
    when(client.reportUser(any, any)).thenAnswer((_) async => {});

    await ReportDatasourceImpl(
      client,
    ).reportUser(userId: '@bob:hs', reason: 'Spam');

    verify(client.reportUser('@bob:hs', 'Spam')).called(1);
    verifyNever(client.ignoreUser(any));
  });

  test('reportUser_whenTheServerFails_throwsReportUserFailed', () async {
    when(
      client.reportUser(any, any),
    ).thenThrow(MatrixException.fromJson({'errcode': 'M_UNRECOGNIZED'}));

    final result = ReportDatasourceImpl(
      client,
    ).reportUser(userId: '@bob:hs', reason: 'Spam');

    await expectLater(
      result,
      throwsA(
        isA<ReportUserFailedException>().having(
          (exception) => exception.userId,
          'userId',
          '@bob:hs',
        ),
      ),
    );
  });

  test('reportUser_whenNobodyIsSignedIn_throwsReportNoClient', () async {
    final result = const ReportDatasourceImpl(
      null,
    ).reportUser(userId: '@bob:hs', reason: 'Spam');

    await expectLater(result, throwsA(isA<ReportNoClientException>()));
  });
}
