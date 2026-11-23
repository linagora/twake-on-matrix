import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/utils/dismissible_media_view.dart';
import 'package:twake_chat/utils/platform_infos.dart';

const _viewerKey = Key('viewer');
const _openButtonKey = Key('open');

// Platform.isXxx cannot be faked, so the expected outcome follows the host:
// a long drag closes the viewer on mobile, a mouse drag never does on desktop.
final _viewerAfterLongDrag = PlatformInfos.isDesktop
    ? findsOneWidget
    : findsNothing;

Widget _childClaimingVerticalDrags({VoidCallback? onTap}) {
  return GestureDetector(
    onTap: onTap,
    onVerticalDragUpdate: (_) {},
    child: const SizedBox.expand(
      key: _viewerKey,
      child: ColoredBox(color: Colors.black),
    ),
  );
}

Future<void> _openViewer(
  WidgetTester tester, {
  required Widget child,
  bool dismissOverChildDrags = false,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            key: _openButtonKey,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => DismissibleMediaView(
                  dismissOverChildDrags: dismissOverChildDrags,
                  itemBuilder: child,
                ),
              ),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.byKey(_openButtonKey));
  await tester.pumpAndSettle();
  expect(find.byKey(_viewerKey), findsOneWidget);
}

void main() {
  group('DismissibleMediaView', () {
    testWidgets('a child claiming vertical drags blocks the default dismiss', (
      tester,
    ) async {
      await _openViewer(tester, child: _childClaimingVerticalDrags());

      await tester.drag(find.byKey(_viewerKey), const Offset(0, 400));
      await tester.pumpAndSettle();

      expect(find.byKey(_viewerKey), findsOneWidget);
    });

    testWidgets(
      'dismissOverChildDrags closes on a downward drag despite the child',
      (tester) async {
        await _openViewer(
          tester,
          child: _childClaimingVerticalDrags(),
          dismissOverChildDrags: true,
        );

        await tester.drag(find.byKey(_viewerKey), const Offset(0, 400));
        await tester.pumpAndSettle();

        expect(find.byKey(_viewerKey), _viewerAfterLongDrag);
      },
    );

    testWidgets('dismissOverChildDrags closes on an upward drag', (
      tester,
    ) async {
      await _openViewer(
        tester,
        child: _childClaimingVerticalDrags(),
        dismissOverChildDrags: true,
      );

      await tester.drag(find.byKey(_viewerKey), const Offset(0, -400));
      await tester.pumpAndSettle();

      expect(find.byKey(_viewerKey), _viewerAfterLongDrag);
    });

    testWidgets('dismissOverChildDrags keeps the viewer open on a short drag', (
      tester,
    ) async {
      await _openViewer(
        tester,
        child: _childClaimingVerticalDrags(),
        dismissOverChildDrags: true,
      );

      await tester.drag(find.byKey(_viewerKey), const Offset(0, 40));
      await tester.pumpAndSettle();

      expect(find.byKey(_viewerKey), findsOneWidget);
    });

    testWidgets('dismissOverChildDrags ignores a horizontal drag', (
      tester,
    ) async {
      await _openViewer(
        tester,
        child: _childClaimingVerticalDrags(),
        dismissOverChildDrags: true,
      );

      await tester.drag(find.byKey(_viewerKey), const Offset(400, 150));
      await tester.pumpAndSettle();

      expect(find.byKey(_viewerKey), findsOneWidget);
    });

    testWidgets('dismissOverChildDrags still lets the child receive taps', (
      tester,
    ) async {
      var taps = 0;
      await _openViewer(
        tester,
        child: _childClaimingVerticalDrags(onTap: () => taps++),
        dismissOverChildDrags: true,
      );

      await tester.tap(find.byKey(_viewerKey));
      await tester.pumpAndSettle();

      expect(taps, 1);
      expect(find.byKey(_viewerKey), findsOneWidget);
    });

    testWidgets(
      'dismissOverChildDrags does not close when a second finger joins',
      (tester) async {
        await _openViewer(
          tester,
          child: _childClaimingVerticalDrags(),
          dismissOverChildDrags: true,
        );
        final center = tester.getCenter(find.byKey(_viewerKey));

        final first = await tester.startGesture(center);
        for (var i = 0; i < 10; i++) {
          await first.moveBy(const Offset(0, 30));
          await tester.pump();
        }
        final second = await tester.startGesture(center + const Offset(80, 0));
        await tester.pump();
        await first.up();
        await second.up();
        await tester.pumpAndSettle();

        expect(find.byKey(_viewerKey), findsOneWidget);
      },
    );

    testWidgets('dismissOverChildDrags does not close on a cancelled pointer', (
      tester,
    ) async {
      await _openViewer(
        tester,
        child: _childClaimingVerticalDrags(),
        dismissOverChildDrags: true,
      );

      final gesture = await tester.startGesture(
        tester.getCenter(find.byKey(_viewerKey)),
      );
      for (var i = 0; i < 10; i++) {
        await gesture.moveBy(const Offset(0, 30));
        await tester.pump();
      }
      await gesture.cancel();
      await tester.pumpAndSettle();

      expect(find.byKey(_viewerKey), findsOneWidget);
    });
  });
}
