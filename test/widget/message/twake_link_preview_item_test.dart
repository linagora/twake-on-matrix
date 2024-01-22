import 'package:fluffychat/widgets/mxc_image.dart';
import 'package:fluffychat/widgets/twake_components/twake_preview_link/twake_link_preview_item_style.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:fluffychat/presentation/model/media/url_preview_presentation.dart';
import 'package:fluffychat/widgets/twake_components/twake_preview_link/twake_link_preview_item.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';

void main() {
  group(
    '[WIDGET TEST] - TwakeLinkPreviewItem is own message\n',
    () {
      const ownMessage = true;

      testWidgets(
        'GIVEN no image uri\n'
        'AND no image width and height\n'
        'AND only title and description\n'
        'THEN not display MxcImage widget',
        (WidgetTester tester) async {
          // Define a UrlPreviewPresentation object
          final urlPreviewPresentation = UrlPreviewPresentation(
            title: 'Test Title',
            description: 'Test Description',
          );

          final twakeLinkPreviewItem = TwakeLinkPreviewItem(
            ownMessage: ownMessage,
            urlPreviewPresentation: urlPreviewPresentation,
          );

          // Build the TwakeLinkPreviewItem widget
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: twakeLinkPreviewItem,
              ),
            ),
          );

          expect(twakeLinkPreviewItem.ownMessage, true);

          final containerFinder = find.byType(Container);

          expect(containerFinder, findsOneWidget);

          final Container containerWidget = tester.widget(containerFinder);

          final ShapeDecoration decoration =
              containerWidget.decoration as ShapeDecoration;

          expect(decoration.color, LinagoraRefColors.material().primary[95]);

          final RoundedRectangleBorder shape =
              decoration.shape as RoundedRectangleBorder;

          expect(
            shape.borderRadius,
            BorderRadius.circular(TwakeLinkPreviewItemStyle.radiusBorder),
          );

          expect(find.text(urlPreviewPresentation.title ?? ''), findsOneWidget);

          expect(
            find.text(urlPreviewPresentation.description ?? ''),
            findsOneWidget,
          );

          expect(find.byType(LinkPreviewNoImage), findsOneWidget);

          expect(find.byType(MxcImage), findsNothing);
        },
      );

      testWidgets(
        'GIVEN an image uri\n'
        'AND no image width and height\n'
        'AND only title and description\n'
        'THEN not display MxcImage widget',
        (WidgetTester tester) async {
          // Define a UrlPreviewPresentation object
          final urlPreviewPresentation = UrlPreviewPresentation(
            imageUri: Uri.parse('https://test.com'),
            title: 'Test Title',
            description: 'Test Description',
          );

          final twakeLinkPreviewItem = TwakeLinkPreviewItem(
            ownMessage: ownMessage,
            urlPreviewPresentation: urlPreviewPresentation,
          );

          // Build the TwakeLinkPreviewItem widget
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: twakeLinkPreviewItem,
              ),
            ),
          );

          expect(twakeLinkPreviewItem.ownMessage, true);

          final containerFinder = find.byType(Container);

          expect(containerFinder, findsOneWidget);

          final Container containerWidget = tester.widget(containerFinder);

          final BoxConstraints constraints =
              containerWidget.constraints as BoxConstraints;

          expect(constraints.minWidth, double.infinity);

          expect(constraints.maxHeight, double.infinity);

          final ShapeDecoration decoration =
              containerWidget.decoration as ShapeDecoration;
          expect(decoration.color, LinagoraRefColors.material().primary[95]);

          final RoundedRectangleBorder shape =
              decoration.shape as RoundedRectangleBorder;

          expect(
            shape.borderRadius,
            BorderRadius.circular(TwakeLinkPreviewItemStyle.radiusBorder),
          );

          expect(find.text(urlPreviewPresentation.title ?? ''), findsOneWidget);

          expect(
            find.text(urlPreviewPresentation.description ?? ''),
            findsOneWidget,
          );

          expect(find.byType(LinkPreviewNoImage), findsOneWidget);

          expect(find.byType(LinkPreviewNoImage), findsOneWidget);

          expect(find.byType(MxcImage), findsNothing);
        },
      );

      testWidgets(
        'GIVEN an image uri\n'
        'AND an image width is null\n'
        'AND only title and description\n'
        'THEN not display MxcImage widget',
        (WidgetTester tester) async {
          // Define a UrlPreviewPresentation object
          final urlPreviewPresentation = UrlPreviewPresentation(
            title: 'Test Title',
            description: 'Test Description',
            imageUri: Uri.parse('https://test.com'),
            imageHeight: 123,
          );

          final twakeLinkPreviewItem = TwakeLinkPreviewItem(
            ownMessage: ownMessage,
            urlPreviewPresentation: urlPreviewPresentation,
          );

          // Build the TwakeLinkPreviewItem widget
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: twakeLinkPreviewItem,
              ),
            ),
          );

          expect(twakeLinkPreviewItem.ownMessage, true);

          final containerFinder = find.byType(Container);

          expect(containerFinder, findsOneWidget);

          final Container containerWidget = tester.widget(containerFinder);

          final BoxConstraints constraints =
              containerWidget.constraints as BoxConstraints;

          expect(constraints.minWidth, double.infinity);

          expect(constraints.maxHeight, double.infinity);

          final ShapeDecoration decoration =
              containerWidget.decoration as ShapeDecoration;
          expect(decoration.color, LinagoraRefColors.material().primary[95]);

          final RoundedRectangleBorder shape =
              decoration.shape as RoundedRectangleBorder;

          expect(
            shape.borderRadius,
            BorderRadius.circular(TwakeLinkPreviewItemStyle.radiusBorder),
          );

          expect(find.text(urlPreviewPresentation.title ?? ''), findsOneWidget);

          expect(
            find.text(urlPreviewPresentation.description ?? ''),
            findsOneWidget,
          );

          expect(find.byType(LinkPreviewNoImage), findsOneWidget);

          expect(find.byType(MxcImage), findsNothing);
        },
      );

      testWidgets(
        'GIVEN an image response\n'
        'AND an image height is null\n'
        'AND only title and description\n'
        'THEN not display MxcImage widget',
        (WidgetTester tester) async {
          // Define a UrlPreviewPresentation object
          final urlPreviewPresentation = UrlPreviewPresentation(
            title: 'Test Title',
            description: 'Test Description',
            imageUri: Uri.parse('https://test.com'),
            imageWidth: 123,
          );

          final twakeLinkPreviewItem = TwakeLinkPreviewItem(
            ownMessage: ownMessage,
            urlPreviewPresentation: urlPreviewPresentation,
          );

          // Build the TwakeLinkPreviewItem widget
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: twakeLinkPreviewItem,
              ),
            ),
          );

          expect(twakeLinkPreviewItem.ownMessage, true);

          final containerFinder = find.byType(Container);

          expect(containerFinder, findsOneWidget);

          final Container containerWidget = tester.widget(containerFinder);

          final ShapeDecoration decoration =
              containerWidget.decoration as ShapeDecoration;
          expect(decoration.color, LinagoraRefColors.material().primary[95]);

          final RoundedRectangleBorder shape =
              decoration.shape as RoundedRectangleBorder;

          expect(
            shape.borderRadius,
            BorderRadius.circular(TwakeLinkPreviewItemStyle.radiusBorder),
          );

          expect(find.text(urlPreviewPresentation.title ?? ''), findsOneWidget);

          expect(
            find.text(urlPreviewPresentation.description ?? ''),
            findsOneWidget,
          );

          expect(find.byType(LinkPreviewNoImage), findsOneWidget);

          expect(find.byType(MxcImage), findsNothing);
        },
      );

      testWidgets(
        'GIVEN an image response\n'
        'AND an image height > 200 \n'
        'AND an image width is not empty\n'
        'AND only title and description\n'
        'THEN not display MxcImage widget',
        (WidgetTester tester) async {
          // Define a UrlPreviewPresentation object
          final urlPreviewPresentation = UrlPreviewPresentation(
            title: 'Test Title',
            description: 'Test Description',
            imageUri: Uri.parse('https://test.com'),
            imageWidth: 123,
            imageHeight: 201,
          );

          final twakeLinkPreviewItem = TwakeLinkPreviewItem(
            ownMessage: ownMessage,
            urlPreviewPresentation: urlPreviewPresentation,
          );

          // Build the TwakeLinkPreviewItem widget
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: twakeLinkPreviewItem,
              ),
            ),
          );

          expect(twakeLinkPreviewItem.ownMessage, true);

          final containerFinder = find.byType(Container);

          expect(containerFinder, findsOneWidget);

          final Container containerWidget = tester.widget(containerFinder);

          final BoxConstraints constraints =
              containerWidget.constraints as BoxConstraints;

          expect(constraints.minWidth, double.infinity);

          expect(constraints.maxHeight, double.infinity);

          final ShapeDecoration decoration =
              containerWidget.decoration as ShapeDecoration;

          expect(decoration.color, LinagoraRefColors.material().primary[95]);

          final RoundedRectangleBorder shape =
              decoration.shape as RoundedRectangleBorder;

          expect(
            shape.borderRadius,
            BorderRadius.circular(TwakeLinkPreviewItemStyle.radiusBorder),
          );

          expect(find.text(urlPreviewPresentation.title ?? ''), findsOneWidget);

          expect(
            find.text(urlPreviewPresentation.description ?? ''),
            findsOneWidget,
          );

          expect(find.byType(LinkPreviewLarge), findsOneWidget);

          expect(find.byType(MxcImage), findsOneWidget);

          final clipRRectFinder = find.byType(ClipRRect);

          expect(clipRRectFinder, findsOneWidget);

          final ClipRRect clipRRectWidget = tester.widget(clipRRectFinder);

          final BorderRadius borderRadius =
              clipRRectWidget.borderRadius as BorderRadius;

          expect(
            borderRadius.topLeft,
            const Radius.circular(TwakeLinkPreviewItemStyle.radiusBorder),
          );

          expect(
            borderRadius.topRight,
            const Radius.circular(TwakeLinkPreviewItemStyle.radiusBorder),
          );

          final mxcImageFinder = find.byType(MxcImage);

          expect(mxcImageFinder, findsOneWidget);

          final MxcImage mxcImage = tester.widget(mxcImageFinder);

          expect(mxcImage.uri, urlPreviewPresentation.imageUri);

          expect(mxcImage.fit, BoxFit.cover);

          expect(mxcImage.isThumbnail, false);
        },
      );

      testWidgets(
        'GIVEN an image response\n'
        'AND an image height < 200 \n'
        'AND an image width is not empty\n'
        'AND only title and description\n'
        'THEN not display MxcImage widget',
        (WidgetTester tester) async {
          // Define a UrlPreviewPresentation object
          final urlPreviewPresentation = UrlPreviewPresentation(
            title: 'Test Title',
            description: 'Test Description',
            imageUri: Uri.parse('https://test.com'),
            imageWidth: 123,
            imageHeight: 199,
          );

          final twakeLinkPreviewItem = TwakeLinkPreviewItem(
            ownMessage: ownMessage,
            urlPreviewPresentation: urlPreviewPresentation,
          );

          // Build the TwakeLinkPreviewItem widget
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: twakeLinkPreviewItem,
              ),
            ),
          );

          expect(twakeLinkPreviewItem.ownMessage, true);

          final containerFinder = find.byType(Container);

          expect(containerFinder, findsOneWidget);

          final Container containerWidget = tester.widget(containerFinder);

          final BoxConstraints constraints =
              containerWidget.constraints as BoxConstraints;

          expect(constraints.minWidth, double.infinity);

          expect(constraints.maxHeight, double.infinity);

          final ShapeDecoration decoration =
              containerWidget.decoration as ShapeDecoration;
          expect(decoration.color, LinagoraRefColors.material().primary[95]);

          final RoundedRectangleBorder shape =
              decoration.shape as RoundedRectangleBorder;

          expect(
            shape.borderRadius,
            BorderRadius.circular(TwakeLinkPreviewItemStyle.radiusBorder),
          );

          expect(find.text(urlPreviewPresentation.title ?? ''), findsOneWidget);

          expect(
            find.text(urlPreviewPresentation.description ?? ''),
            findsOneWidget,
          );

          expect(find.byType(LinkPreviewSmall), findsOneWidget);

          final mxcImageFinder = find.byType(MxcImage);

          expect(mxcImageFinder, findsOneWidget);

          final clipRRectFinder = find.byType(ClipRRect);

          expect(clipRRectFinder, findsOneWidget);

          final ClipRRect clipRRectWidget = tester.widget(clipRRectFinder);

          final BorderRadius borderRadius =
              clipRRectWidget.borderRadius as BorderRadius;

          expect(
            borderRadius.topLeft,
            const Radius.circular(TwakeLinkPreviewItemStyle.radiusBorder),
          );

          expect(
            borderRadius.topRight,
            const Radius.circular(TwakeLinkPreviewItemStyle.radiusBorder),
          );

          final MxcImage mxcImage = tester.widget(mxcImageFinder);

          expect(mxcImage.uri, urlPreviewPresentation.imageUri);

          expect(
            mxcImage.width,
            TwakeLinkPreviewItemStyle.heightMxcImagePreview,
          );

          expect(
            mxcImage.width,
            TwakeLinkPreviewItemStyle.heightMxcImagePreview,
          );

          expect(mxcImage.fit, BoxFit.cover);

          expect(mxcImage.isThumbnail, false);
        },
      );
    },
  );

  group(
    '[WIDGET TEST] - TwakeLinkPreviewItem is not own message\n',
    () {
      const ownMessage = false;
      testWidgets(
        'GIVEN no image uri\n'
        'AND no image width and height\n'
        'AND only title and description\n'
        'THEN not display MxcImage widget',
        (WidgetTester tester) async {
          // Define a UrlPreviewPresentation object
          final urlPreviewPresentation = UrlPreviewPresentation(
            title: 'Test Title',
            description: 'Test Description',
          );

          final twakeLinkPreviewItem = TwakeLinkPreviewItem(
            ownMessage: ownMessage,
            urlPreviewPresentation: urlPreviewPresentation,
          );

          // Build the TwakeLinkPreviewItem widget
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: twakeLinkPreviewItem,
              ),
            ),
          );

          expect(twakeLinkPreviewItem.ownMessage, false);

          final containerFinder = find.byType(Container);

          expect(containerFinder, findsOneWidget);

          final Container containerWidget = tester.widget(containerFinder);

          final BoxConstraints constraints =
              containerWidget.constraints as BoxConstraints;

          expect(constraints.minWidth, double.infinity);

          expect(constraints.maxHeight, double.infinity);

          final ShapeDecoration decoration =
              containerWidget.decoration as ShapeDecoration;

          expect(
            decoration.color,
            LinagoraStateLayer(
              LinagoraSysColors.material().surfaceTint,
            ).opacityLayer1,
          );

          final RoundedRectangleBorder shape =
              decoration.shape as RoundedRectangleBorder;

          expect(
            shape.borderRadius,
            BorderRadius.circular(TwakeLinkPreviewItemStyle.radiusBorder),
          );

          expect(find.text(urlPreviewPresentation.title ?? ''), findsOneWidget);

          expect(
            find.text(urlPreviewPresentation.description ?? ''),
            findsOneWidget,
          );

          expect(find.byType(LinkPreviewNoImage), findsOneWidget);

          expect(find.byType(MxcImage), findsNothing);
        },
      );
    },
  );
}
