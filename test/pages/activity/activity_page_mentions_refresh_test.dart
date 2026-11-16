import 'package:flutter_test/flutter_test.dart';

import 'activity_mentions_test_support.dart';
import 'activity_test_support.dart';

/// THR-M-12, slice 2, found on the real app (QA 2026-11-12): the tab badge
/// showed a new mention while the list « Mentions », open, still showed the
/// old ones. When the count of the unread mentions changes while the list is
/// shown, the mentions are read again from the server; the same count again
/// reads nothing.
void main() {
  late FakeActivityRepository repository;
  late FakeActivityMentionsRepository mentions;

  const designId = '!design:example.org';

  final oldMention = MentionItem(
    roomId: designId,
    roomName: 'Design',
    eventId: r'$old',
    time: 9.today,
    author: 'Dan Brown',
    text: '@me can you check the mockups?',
  ).item;
  final newMention = MentionItem(
    roomId: designId,
    roomName: 'Design',
    eventId: r'$new',
    time: 11.today,
    author: 'Erin Gray',
    text: '@me the budget numbers are in',
  ).item;

  setUp(() {
    repository = FakeActivityRepository();
    mentions = FakeActivityMentionsRepository(mentions: [oldMention]);
  });

  /// The list « Mentions » is shown; returns the reads done so far.
  Future<int> showMentions(WidgetTester tester) async {
    await pumpActivityPage(
      tester,
      ActivityPageSetup(repository: repository, mentions: mentions),
    );
    await selectFilter(tester, 'Mentions');
    expect(
      find.textContaining('can you check the mockups?', findRichText: true),
      findsOneWidget,
    );
    return mentions.reads;
  }

  testWidgets('a new unread mention shows in the open list without leaving '
      'it', (tester) async {
    final readsBefore = await showMentions(tester);

    mentions.mentions = [newMention, oldMention];
    repository.setMentionCount(1);
    await tester.pumpAndSettle();

    expect(mentions.reads, readsBefore + 1);
    expect(
      find.textContaining('the budget numbers are in', findRichText: true),
      findsOneWidget,
    );
  });

  testWidgets('the same unread mentions count again reads nothing', (
    tester,
  ) async {
    await showMentions(tester);
    repository.setMentionCount(1);
    await tester.pumpAndSettle();
    final readsAfterChange = mentions.reads;

    repository.setMentionCount(1);
    await tester.pumpAndSettle();

    expect(mentions.reads, readsAfterChange);
  });
}
