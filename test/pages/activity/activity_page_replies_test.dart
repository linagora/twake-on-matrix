import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/config/go_routes/app_routes.dart';

import 'activity_test_support.dart';

/// THR-M-12 (docs/plan/2026-11-06-threads-mobile-spec.md), slice 1, filter
/// « Replies » (web D185: Replies lists the threads the user follows): the
/// author and text of the last reply, the room, a check when resolved, the
/// unread count; touching it opens the thread screen; empty, « No thread
/// followed yet. »; a reply from another device updates the list without a
/// refresh.
void main() {
  late FakeActivityRepository repository;

  const designId = '!design:example.org';
  const rootId = r'$release';

  final release = FollowedThreadItem(
    roomId: designId,
    roomName: 'Design',
    rootId: rootId,
    rootText: 'Release plan for Friday',
    time: 10.today,
    author: 'Alice Durand',
    lastReply: 'Ship it',
    unreadCount: 2,
    isResolved: true,
  ).item;
  final unreadRoom = UnreadRoomItem(
    roomId: '!sales:example.org',
    roomName: 'Sales',
    time: 11.today,
    lastMessage: 'numbers are in',
  ).item;

  setUp(() {
    repository = FakeActivityRepository(items: [release, unreadRoom]);
  });

  testWidgets('a followed thread shows the author and the text of its last '
      'reply', (tester) async {
    await pumpActivityPage(tester, ActivityPageSetup(repository: repository));
    await selectFilter(tester, 'Replies');

    expect(
      find.textContaining('Alice Durand', findRichText: true),
      findsOneWidget,
    );
    expect(find.textContaining('Ship it', findRichText: true), findsOneWidget);
  });

  testWidgets('a followed thread shows its room and the start of its root', (
    tester,
  ) async {
    await pumpActivityPage(tester, ActivityPageSetup(repository: repository));
    await selectFilter(tester, 'Replies');

    expect(find.textContaining('Design', findRichText: true), findsWidgets);
    expect(
      find.textContaining('Release plan', findRichText: true),
      findsOneWidget,
    );
  });

  testWidgets('a followed thread shows its unread count', (tester) async {
    await pumpActivityPage(tester, ActivityPageSetup(repository: repository));
    await selectFilter(tester, 'Replies');

    expect(find.text('2'), findsOneWidget);
  });

  testWidgets('a followed thread with nothing unread shows no count', (
    tester,
  ) async {
    repository = FakeActivityRepository(
      items: [
        FollowedThreadItem(
          roomId: designId,
          roomName: 'Design',
          rootId: rootId,
          time: 10.today,
        ).item,
      ],
    );
    await pumpActivityPage(tester, ActivityPageSetup(repository: repository));
    await selectFilter(tester, 'Replies');

    expect(find.text('0'), findsNothing);
  });

  testWidgets('a resolved thread carries the « Resolved » check', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await pumpActivityPage(tester, ActivityPageSetup(repository: repository));
    await selectFilter(tester, 'Replies');

    expect(find.bySemanticsLabel('Resolved'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('a thread not resolved carries no check', (tester) async {
    final semantics = tester.ensureSemantics();
    repository = FakeActivityRepository(
      items: [
        FollowedThreadItem(
          roomId: designId,
          roomName: 'Design',
          rootId: rootId,
          time: 10.today,
        ).item,
      ],
    );
    await pumpActivityPage(tester, ActivityPageSetup(repository: repository));
    await selectFilter(tester, 'Replies');

    expect(find.bySemanticsLabel('Resolved'), findsNothing);
    semantics.dispose();
  });

  testWidgets('« Replies » lists the followed threads only, not the unread '
      'rooms', (tester) async {
    await pumpActivityPage(tester, ActivityPageSetup(repository: repository));
    await selectFilter(tester, 'Replies');

    expect(
      find.textContaining('numbers are in', findRichText: true),
      findsNothing,
    );
    expect(find.text('Mark as read'), findsNothing);
  });

  testWidgets('with no thread followed, « Replies » says « No thread followed '
      'yet. »', (tester) async {
    repository = FakeActivityRepository(items: [unreadRoom]);
    await pumpActivityPage(tester, ActivityPageSetup(repository: repository));
    await selectFilter(tester, 'Replies');

    expect(find.text('No thread followed yet.'), findsOneWidget);
  });

  testWidgets('touching a followed thread opens the thread screen of that '
      'thread', (tester) async {
    await pumpActivityPage(tester, ActivityPageSetup(repository: repository));
    await selectFilter(tester, 'Replies');

    await tester.tap(find.textContaining('Ship it', findRichText: true));
    await tester.pumpAndSettle();

    // The thread screen opens at its bottom; a target reply is allowed.
    final opened = find.textContaining(
      openedText(const ThreadRoute(roomid: designId, rootid: rootId).location),
    );
    expect(opened, findsOneWidget);
  });

  testWidgets('a reply sent from another device shows as the last reply '
      'without a refresh', (tester) async {
    await pumpActivityPage(tester, ActivityPageSetup(repository: repository));
    await selectFilter(tester, 'Replies');

    repository.emit([
      FollowedThreadItem(
        roomId: designId,
        roomName: 'Design',
        rootId: rootId,
        time: 12.today,
        author: 'Me Myself',
        lastReply: 'On it',
      ).item,
      unreadRoom,
    ]);
    await tester.pumpAndSettle();

    expect(find.textContaining('On it', findRichText: true), findsOneWidget);
    expect(find.textContaining('Ship it', findRichText: true), findsNothing);
  });

  testWidgets('a thread the user starts to follow elsewhere joins « Replies » '
      'without a refresh', (tester) async {
    repository = FakeActivityRepository(items: [unreadRoom]);
    await pumpActivityPage(tester, ActivityPageSetup(repository: repository));
    await selectFilter(tester, 'Replies');
    expect(find.text('No thread followed yet.'), findsOneWidget);

    repository.emit([release, unreadRoom]);
    await tester.pumpAndSettle();

    expect(find.textContaining('Ship it', findRichText: true), findsOneWidget);
    expect(find.text('No thread followed yet.'), findsNothing);
  });
}
