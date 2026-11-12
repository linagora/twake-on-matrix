import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/config/go_routes/app_routes.dart';

import 'activity_test_support.dart';

/// THR-M-12 (docs/plan/2026-11-06-threads-mobile-spec.md), slice 1, filter
/// « Unread » (web D57): one item per unread room, with the room, its
/// unread count and its last message; « Mark as read » on the row reads the
/// room (main timeline and unread threads) and the room leaves « Unread »;
/// touching the row opens the room.
void main() {
  late FakeActivityRepository repository;

  const designId = '!design:example.org';
  const salesId = '!sales:example.org';

  final design = unreadRoomItem(
    roomId: designId,
    roomName: 'Design',
    time: todayAt(11),
    unreadCount: 3,
    author: 'Bob Martin',
    lastMessage: 'see you there',
  );
  final sales = unreadRoomItem(
    roomId: salesId,
    roomName: 'Sales',
    time: todayAt(9),
    unreadCount: 5,
    author: 'Carol King',
    lastMessage: 'numbers are in',
  );
  final followed = followedThreadItem(
    roomId: designId,
    roomName: 'Design',
    rootId: r'$release',
    time: todayAt(10),
    lastReply: 'Ship it',
  );

  setUp(() {
    repository = FakeActivityRepository(items: [design, sales, followed]);
  });

  testWidgets('an unread room shows its name, its unread count and its last '
      'message', (tester) async {
    await pumpActivityPage(tester, repository: repository);
    await selectFilter(tester, 'Unread');

    expect(find.textContaining('Design', findRichText: true), findsWidgets);
    expect(find.text('3'), findsOneWidget);
    expect(
      find.textContaining('Bob Martin', findRichText: true),
      findsOneWidget,
    );
    expect(
      find.textContaining('see you there', findRichText: true),
      findsOneWidget,
    );
  });

  testWidgets('« Unread » lists the unread rooms only, not the followed '
      'threads', (tester) async {
    await pumpActivityPage(tester, repository: repository);
    await selectFilter(tester, 'Unread');

    expect(find.textContaining('see you there', findRichText: true), findsOne);
    expect(find.textContaining('numbers are in', findRichText: true), findsOne);
    expect(find.textContaining('Ship it', findRichText: true), findsNothing);
  });

  testWidgets('every unread room has its own « Mark as read » button', (
    tester,
  ) async {
    await pumpActivityPage(tester, repository: repository);
    await selectFilter(tester, 'Unread');

    expect(find.text('Mark as read'), findsNWidgets(2));
  });

  testWidgets('« Mark as read » reads that room and it leaves « Unread »', (
    tester,
  ) async {
    await pumpActivityPage(tester, repository: repository);
    await selectFilter(tester, 'Unread');

    // Newest first: the first row is Design (11:00), then Sales (9:00).
    await tester.tap(find.text('Mark as read').first);
    await tester.pumpAndSettle();

    expect(repository.markedRead, [designId]);
    expect(
      find.textContaining('see you there', findRichText: true),
      findsNothing,
    );
    expect(
      find.textContaining('numbers are in', findRichText: true),
      findsOneWidget,
      reason: 'the other unread room stays',
    );
  });

  testWidgets('« Mark as read » does not open the room', (tester) async {
    await pumpActivityPage(tester, repository: repository);
    await selectFilter(tester, 'Unread');

    await tester.tap(find.text('Mark as read').first);
    await tester.pumpAndSettle();

    expect(find.textContaining('opened'), findsNothing);
  });

  testWidgets('when « Mark as read » fails, the room stays in « Unread » and '
      'can be marked again', (tester) async {
    repository.markReadError = Exception('offline');
    await pumpActivityPage(tester, repository: repository);
    await selectFilter(tester, 'Unread');

    await tester.tap(find.text('Mark as read').first);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(
      find.textContaining('see you there', findRichText: true),
      findsOneWidget,
    );
    expect(find.text('Mark as read'), findsNWidgets(2));
  });

  testWidgets('touching an unread room opens the room', (tester) async {
    await pumpActivityPage(tester, repository: repository);
    await selectFilter(tester, 'Unread');

    await tester.tap(find.textContaining('see you there', findRichText: true));
    await tester.pumpAndSettle();

    expect(
      find.text(openedText(const RoomRoute(roomid: designId).location)),
      findsOneWidget,
    );
  });

  testWidgets('a room read elsewhere leaves « Unread » without a refresh', (
    tester,
  ) async {
    await pumpActivityPage(tester, repository: repository);
    await selectFilter(tester, 'Unread');

    repository.emit([sales, followed]);
    await tester.pumpAndSettle();

    expect(
      find.textContaining('see you there', findRichText: true),
      findsNothing,
    );
    expect(find.text('Mark as read'), findsOneWidget);
  });

  testWidgets('a room that gets a new message joins « Unread » without a '
      'refresh', (tester) async {
    await pumpActivityPage(tester, repository: repository);
    await selectFilter(tester, 'Unread');

    repository.emit([
      design,
      sales,
      followed,
      unreadRoomItem(
        roomId: '!ops:example.org',
        roomName: 'Ops',
        time: todayAt(12),
        lastMessage: 'server is down',
      ),
    ]);
    await tester.pumpAndSettle();

    expect(
      find.textContaining('server is down', findRichText: true),
      findsOneWidget,
    );
    expect(find.text('Mark as read'), findsNWidgets(3));
  });
}
