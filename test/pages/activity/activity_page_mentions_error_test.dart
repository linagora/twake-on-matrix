import 'package:flutter_test/flutter_test.dart';

import 'activity_mentions_test_support.dart';
import 'activity_test_support.dart';

/// THR-M-12, slice 2, found on the real app (QA 2026-11-12, offline): when
/// the mentions cannot be read, the list showed a lone « Try again » with
/// nothing saying what failed. A short text says the mentions could not be
/// loaded, with « Try again ».
///
/// The text is the new key `activityMentionsLoadFailed`, English « The
/// mentions could not be loaded. ».
void main() {
  const failure = 'The mentions could not be loaded.';

  late FakeActivityRepository repository;
  late FakeActivityMentionsRepository mentions;

  setUp(() {
    repository = FakeActivityRepository();
    mentions = FakeActivityMentionsRepository(
      mentions: [
        mentionItem(
          roomId: '!design:example.org',
          roomName: 'Design',
          eventId: r'$ask',
          time: todayAt(11),
          text: '@me can you check the mockups?',
        ),
      ],
    )..error = Exception('offline');
  });

  testWidgets('when the mentions cannot be read, a text says so, with « Try '
      'again »', (tester) async {
    await pumpActivityPage(tester, repository: repository, mentions: mentions);
    await selectFilter(tester, 'Mentions');

    expect(find.text(failure), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
  });

  testWidgets('once « Try again » reads them, the text leaves with the '
      'error', (tester) async {
    await pumpActivityPage(tester, repository: repository, mentions: mentions);
    await selectFilter(tester, 'Mentions');

    mentions.error = null;
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();

    expect(find.text(failure), findsNothing);
    expect(
      find.textContaining('can you check the mockups?', findRichText: true),
      findsOneWidget,
    );
  });
}
