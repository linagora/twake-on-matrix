import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:matrix/matrix.dart';
import 'package:twake_chat/utils/offline_failure.dart';

void main() {
  final offline = <Object>[
    const SocketException('offline'),
    TimeoutException('offline'),
    http.ClientException('offline'),
    SyncConnectionException(const SocketException('offline')),
    SyncConnectionException(TimeoutException('offline')),
    SyncConnectionException(http.ClientException('offline')),
  ];

  test('a lost connection is an offline failure, anything else is not', () {
    for (final error in offline) {
      expect(isOfflineFailure(error), isTrue, reason: '$error');
    }
    expect(isOfflineFailure(StateError('bug')), isFalse);
    expect(
      isOfflineFailure(SyncConnectionException(StateError('bug'))),
      isFalse,
    );
  });

  test('only an offline failure is logged, and only as a warning', () {
    final events = <LogEvent>[];
    final previous = Logs().onLog;
    Logs().onLog = events.add;
    addTearDown(() => Logs().onLog = previous);

    expect(
      warnIfOffline(
        const SocketException('offline'),
        StackTrace.empty,
        'sync failed, offline',
      ),
      isTrue,
    );
    expect(warnIfOffline(StateError('bug'), StackTrace.empty, 'bug'), isFalse);

    expect(events, hasLength(1));
    expect(events.single.level, Level.warning);
    expect(events.single.title, 'sync failed, offline');
    expect(events.single.exception, isA<SocketException>());
  });
}
