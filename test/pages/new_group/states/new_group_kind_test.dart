import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/pages/new_group/states/new_group_kind.dart';

void main() {
  group('NewGroupKind.isMemberRequired', () {
    test('aPlainGroupOrFeed_needsSomeone', () {
      expect(NewGroupKind.group.isMemberRequired(), isTrue);
      expect(NewGroupKind.feed.isMemberRequired(), isTrue);
    });

    test('aSpace_canStartAlone', () {
      expect(NewGroupKind.space.isMemberRequired(), isFalse);
    });

    test('aGroupInASpace_canStartAlone', () {
      expect(NewGroupKind.group.isMemberRequired(parentSpaceId: '!s'), isFalse);
    });
  });
}
