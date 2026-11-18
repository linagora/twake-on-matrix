import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/utils/extension/share_position_origin_extension.dart';

void main() {
  group('SharePositionOriginExtension.shareOriginOf', () {
    test('returns null without a render box', () {
      expect(SharePositionOriginExtension.shareOriginOf(null), isNull);
    });

    test('returns null for a box that has no size yet', () {
      final box = RenderConstrainedBox(
        additionalConstraints: const BoxConstraints.tightFor(
          width: 10,
          height: 10,
        ),
      );

      expect(box.hasSize, isFalse);
      expect(SharePositionOriginExtension.shareOriginOf(box), isNull);
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
      final origin = SharePositionOriginExtension.shareOriginOf(box);

      expect(origin, tester.getRect(find.byKey(key)));
      expect(origin!.size, const Size(120, 40));
      expect(origin.topLeft, isNot(Offset.zero));
    });
  });
}
