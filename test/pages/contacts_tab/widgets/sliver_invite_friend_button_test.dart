import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/pages/contacts_tab/widgets/sliver_invite_friend_button.dart';

void main() {
  group('SliverInviteFriendButton.shareOriginOf', () {
    test('returns null without a render box', () {
      expect(SliverInviteFriendButton.shareOriginOf(null), isNull);
    });

    test('returns null for a box that has no size yet', () {
      final box = RenderConstrainedBox(
        additionalConstraints: const BoxConstraints.tightFor(
          width: 10,
          height: 10,
        ),
      );

      expect(box.hasSize, isFalse);
      expect(SliverInviteFriendButton.shareOriginOf(box), isNull);
    });

    testWidgets('returns the global rect of a laid out box', (tester) async {
      const key = Key('anchor');
      await tester.pumpWidget(
        const Align(
          alignment: Alignment.bottomRight,
          child: SizedBox(key: key, width: 120, height: 40),
        ),
      );

      final box = tester.renderObject<RenderBox>(find.byKey(key));
      final origin = SliverInviteFriendButton.shareOriginOf(box);

      expect(origin, tester.getRect(find.byKey(key)));
      expect(origin!.size, const Size(120, 40));
      expect(origin.topLeft, isNot(Offset.zero));
    });
  });
}
