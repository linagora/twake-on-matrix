import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:twake_chat/data/datasource_impl/report/report_datasource_impl.dart';
import 'package:twake_chat/domain/exception/report/report_exception.dart';

import 'report_datasource_impl_test.mocks.dart';

typedef _ReportCase = ({
  String name,
  String target,
  Future<void> Function(MockClient client) sent,
  void Function(MockClient client, Exception error) failWith,
  Future<void> Function(ReportDatasourceImpl datasource) send,
  String failureName,
  Matcher failure,
});

final List<_ReportCase> _cases = [
  (
    name: 'reportRoom',
    target: 'RoomId',
    sent: (client) async {
      verify(client.reportRoom('!room:hs', 'Spam')).called(1);
    },
    failWith: (client, error) =>
        when(client.reportRoom(any, any)).thenThrow(error),
    send: (datasource) =>
        datasource.reportRoom(roomId: '!room:hs', reason: 'Spam'),
    failureName: 'ReportRoomFailed',
    failure: isA<ReportRoomFailedException>().having(
      (exception) => exception.roomId,
      'roomId',
      '!room:hs',
    ),
  ),
  (
    name: 'reportUser',
    target: 'UserId',
    sent: (client) async {
      verify(client.reportUser('@bob:hs', 'Spam')).called(1);
      verifyNever(client.ignoreUser(any));
    },
    failWith: (client, error) =>
        when(client.reportUser(any, any)).thenThrow(error),
    send: (datasource) =>
        datasource.reportUser(userId: '@bob:hs', reason: 'Spam'),
    failureName: 'ReportUserFailed',
    failure: isA<ReportUserFailedException>().having(
      (exception) => exception.userId,
      'userId',
      '@bob:hs',
    ),
  ),
];

@GenerateNiceMocks([MockSpec<Client>()])
void main() {
  late MockClient client;

  setUp(() {
    client = MockClient();
    when(client.reportRoom(any, any)).thenAnswer((_) async {});
    when(client.reportUser(any, any)).thenAnswer((_) async => {});
  });

  for (final report in _cases) {
    test(
      '${report.name}_whenTheServerAccepts_sendsThe${report.target}AndReason',
      () async {
        await report.send(ReportDatasourceImpl(client));

        await report.sent(client);
      },
    );

    test(
      '${report.name}_whenTheServerFails_throws${report.failureName}',
      () async {
        report.failWith(
          client,
          MatrixException.fromJson({'errcode': 'M_FORBIDDEN'}),
        );

        await expectLater(
          report.send(ReportDatasourceImpl(client)),
          throwsA(report.failure),
        );
      },
    );

    test('${report.name}_whenNobodyIsSignedIn_throwsReportNoClient', () async {
      await expectLater(
        report.send(const ReportDatasourceImpl(null)),
        throwsA(isA<ReportNoClientException>()),
      );
    });
  }
}
