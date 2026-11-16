import 'dart:async';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:twake_chat/pages/activity/activity_page.dart';

import 'activity_test_support.dart';

/// THR-M-12, « Mark all read » with many unread rooms (review of #3625,
/// activity_page.dart:36): the app sends at most 3 read receipts at a time,
/// so a long list does not hit the rate limit of the server. Every room is
/// still read, and a room that cannot be read does not stop the others: it
/// stays in the list with its « Mark as read », as a single « Mark as read »
/// that fails does.
void main() {
  const roomCount = 10;
  final roomIds = [for (var i = 0; i < roomCount; i++) '!room$i:example.org'];
  final unreadRooms = [
    for (var i = 0; i < roomCount; i++)
      UnreadRoomItem(
        roomId: roomIds[i],
        roomName: 'Room $i',
        time: (12, i).today,
        lastMessage: 'last message of room $i',
      ).item,
  ];

  late _SlowServerRepository repository;

  setUp(() {
    repository = _SlowServerRepository(items: unreadRooms);
  });

  testWidgets('with many unread rooms, « Mark all read » sends at most 3 read '
      'receipts at a time', (tester) async {
    await pumpActivityPage(tester, ActivityPageSetup(repository: repository));

    await tester.tap(find.text('Mark all read'));
    await tester.pump();

    expect(
      repository.inFlight,
      lessThanOrEqualTo(3),
      reason: 'before the server answers any of them',
    );

    await repository.answerAll(tester);
    expect(repository.mostInFlight, lessThanOrEqualTo(3));
  });

  testWidgets('with many unread rooms, « Mark all read » still reads every '
      'one of them', (tester) async {
    await pumpActivityPage(tester, ActivityPageSetup(repository: repository));

    await tester.tap(find.text('Mark all read'));
    await repository.answerAll(tester);

    expect(repository.markedRead, unorderedEquals(roomIds));
    expect(find.text('Mark as read'), findsNothing);
  });

  /// Review of #3625 (activity_page.dart:41, jbrnzl): the user leaves the
  /// tab while the receipts are on their way; the rooms not asked yet must
  /// still be read.
  testWidgets('leaving the Activity tab while « Mark all read » runs still '
      'reads every room', (tester) async {
    await pumpActivityPage(tester, ActivityPageSetup(repository: repository));

    await tester.tap(find.text('Mark all read'));
    await tester.pump();
    GoRouter.of(
      tester.element(find.byType(ActivityPage)),
    ).go('/rooms/!elsewhere:example.org');
    await tester.pumpAndSettle();
    expect(find.byType(ActivityPage), findsNothing, reason: 'the tab is left');

    await repository.answerAll(tester);

    expect(repository.markedRead, unorderedEquals(roomIds));
  });

  testWidgets('when one room cannot be read, « Mark all read » still reads '
      'the others and that room stays in the list', (tester) async {
    // The first room asked: its failure comes while others are waiting.
    const stays = 0;
    repository.failing.add(roomIds[stays]);
    await pumpActivityPage(tester, ActivityPageSetup(repository: repository));

    await tester.tap(find.text('Mark all read'));
    await repository.answerAll(tester);

    expect(tester.takeException(), isNull);
    expect(
      repository.markedRead,
      unorderedEquals(roomIds.where((id) => id != roomIds[stays])),
    );
    expect(
      find.textContaining('last message of room $stays', findRichText: true),
      findsOneWidget,
    );
    expect(find.text('Mark as read'), findsOneWidget);
  });
}

/// The server answers a read receipt only when the test says so
/// ([answerAll]); a room of [failing] cannot be read. [inFlight]: the
/// receipts sent and not answered yet; [mostInFlight]: the most there were
/// at the same time.
class _SlowServerRepository extends FakeActivityRepository {
  _SlowServerRepository({required super.items});

  final Set<String> failing = {};
  int inFlight = 0;
  int mostInFlight = 0;
  final List<Completer<void>> _unanswered = [];

  @override
  Future<void> markRoomRead(String roomId) async {
    inFlight++;
    mostInFlight = max(mostInFlight, inFlight);
    final answer = Completer<void>();
    _unanswered.add(answer);
    try {
      await answer.future;
      if (failing.contains(roomId)) throw Exception('offline');
      await super.markRoomRead(roomId);
    } finally {
      inFlight--;
    }
  }

  /// The server answers every receipt sent, then the ones sent meanwhile,
  /// until none is left (a bounded number of rounds: a page that keeps
  /// sending fails the spec instead of hanging it).
  Future<void> answerAll(WidgetTester tester) async {
    for (var round = 0; round < 100; round++) {
      await tester.pump();
      if (_unanswered.isEmpty) break;
      final answering = [..._unanswered];
      _unanswered.clear();
      for (final answer in answering) {
        answer.complete();
      }
    }
    await tester.pumpAndSettle();
    expect(_unanswered, isEmpty, reason: 'every receipt got its answer');
  }
}
