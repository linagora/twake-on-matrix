import 'package:fluffychat/widgets/mxc_image.dart';
import 'package:fluffychat/widgets/twake_components/twake_preview_link/twake_link_preview.dart';
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
            key: TwakeLinkPreviewController.twakeLinkPreviewItemKey,
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

          final twakeLinkPreviewItemFind = find.byKey(
            TwakeLinkPreviewItem.linkPreviewBodyKey,
          );

          expect(twakeLinkPreviewItemFind, findsOneWidget);

          final Container twakeLinkPreviewItemBody =
              tester.widget(twakeLinkPreviewItemFind);

          expect(twakeLinkPreviewItemBody.decoration != null, true);

          final ShapeDecoration twakeLinkPreviewItemBodyDecoration =
              twakeLinkPreviewItemBody.decoration as ShapeDecoration;

          expect(
            twakeLinkPreviewItemBodyDecoration.color,
            LinagoraSysColors.material().primaryContainer,
          );

          expect(twakeLinkPreviewItemBodyDecoration.shape, isNotNull);

          final RoundedRectangleBorder shape =
              twakeLinkPreviewItemBodyDecoration.shape
                  as RoundedRectangleBorder;

          expect(
            shape.borderRadius,
            BorderRadius.circular(TwakeLinkPreviewItemStyle.radiusBorder),
          );

          final linkPreviewNoImageBody = find.byKey(
            LinkPreviewBuilder.imageDefaultKey,
          );

          expect(linkPreviewNoImageBody, findsOneWidget);

          final paddingTitleFind = find.byKey(
            LinkPreviewBuilder.paddingTitleKey,
          );

          final paddingSubtitleKey = find.byKey(
            LinkPreviewBuilder.paddingSubtitleKey,
          );

          final Padding paddingTitleWidget = tester.widget(
            paddingTitleFind,
          );

          final Padding paddingSubtitleWidget = tester.widget(
            paddingSubtitleKey,
          );

          expect(
            paddingTitleWidget.padding,
            TwakeLinkPreviewItemStyle.paddingTitle,
          );

          expect(
            paddingSubtitleWidget.padding,
            TwakeLinkPreviewItemStyle.paddingSubtitle,
          );

          final titleTextFind = find.byKey(
            LinkPreviewBuilder.titleKey,
          );

          final textSubtitleKeyTextFind = find.byKey(
            LinkPreviewBuilder.subtitleKey,
          );

          expect(titleTextFind, findsOneWidget);

          expect(textSubtitleKeyTextFind, findsOneWidget);

          final Text titleTextWidget = tester.widget(titleTextFind);

          final Text subtitleTextWidget =
              tester.widget(textSubtitleKeyTextFind);

          expect(
            titleTextWidget.data,
            urlPreviewPresentation.title,
          );

          expect(
            subtitleTextWidget.data,
            urlPreviewPresentation.description,
          );

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
            key: TwakeLinkPreviewController.twakeLinkPreviewItemKey,
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

          final linkPreviewNoImageBody = find.byKey(
            LinkPreviewBuilder.imageDefaultKey,
          );

          expect(linkPreviewNoImageBody, findsOneWidget);

          final paddingTitleFind = find.byKey(
            LinkPreviewBuilder.paddingTitleKey,
          );

          final paddingSubtitleKey = find.byKey(
            LinkPreviewBuilder.paddingSubtitleKey,
          );

          final Padding paddingTitleWidget = tester.widget(
            paddingTitleFind,
          );

          final Padding paddingSubtitleWidget = tester.widget(
            paddingSubtitleKey,
          );

          expect(
            paddingTitleWidget.padding,
            TwakeLinkPreviewItemStyle.paddingTitle,
          );

          expect(
            paddingSubtitleWidget.padding,
            TwakeLinkPreviewItemStyle.paddingSubtitle,
          );

          final titleTextFind = find.byKey(
            LinkPreviewBuilder.titleKey,
          );

          final textSubtitleKeyTextFind = find.byKey(
            LinkPreviewBuilder.subtitleKey,
          );

          expect(titleTextFind, findsOneWidget);

          expect(textSubtitleKeyTextFind, findsOneWidget);

          final Text titleTextWidget = tester.widget(titleTextFind);

          final Text subtitleTextWidget =
              tester.widget(textSubtitleKeyTextFind);

          expect(
            titleTextWidget.data,
            urlPreviewPresentation.title,
          );

          expect(
            subtitleTextWidget.data,
            urlPreviewPresentation.description,
          );

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
            key: TwakeLinkPreviewController.twakeLinkPreviewItemKey,
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

          final linkPreviewNoImageBody = find.byKey(
            LinkPreviewBuilder.imageDefaultKey,
          );

          expect(linkPreviewNoImageBody, findsOneWidget);

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
            key: TwakeLinkPreviewController.twakeLinkPreviewItemKey,
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

          final linkPreviewNoImageBody = find.byKey(
            LinkPreviewBuilder.imageDefaultKey,
          );

          expect(linkPreviewNoImageBody, findsOneWidget);

          expect(find.byType(MxcImage), findsNothing);
        },
      );

      testWidgets(
        'GIVEN an image response\n'
        'AND an image height > 200 \n'
        'AND an image width is not empty\n'
        'AND only title and description\n'
        'THEN display MxcImage widget large',
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
            key: TwakeLinkPreviewController.twakeLinkPreviewItemKey,
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

          final linkPreviewLargeBody = find.byKey(
            TwakeLinkPreviewItem.linkPreviewLargeKey,
          );

          expect(linkPreviewLargeBody, findsOneWidget);

          final clipRRectMxcImage = find.byKey(
            LinkPreviewBuilder.clipRRectKey,
          );

          expect(clipRRectMxcImage, findsOneWidget);

          final ClipRRect clipRRectWidget = tester.widget(clipRRectMxcImage);

          expect(
            clipRRectWidget.borderRadius,
            equals(
              const BorderRadius.vertical(
                top: Radius.circular(
                  TwakeLinkPreviewItemStyle.radiusBorder,
                ),
                bottom: Radius.circular(
                  TwakeLinkPreviewItemStyle.radiusBorder,
                ),
              ),
            ),
          );

          final mxcImageFinder = find.byKey(
            LinkPreviewBuilder.mxcImageKey,
          );

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
        'THEN display MxcImage widget small',
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
            key: TwakeLinkPreviewController.twakeLinkPreviewItemKey,
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

          final mxcImageFinder = find.byKey(
            LinkPreviewBuilder.mxcImageKey,
          );

          expect(mxcImageFinder, findsOneWidget);

          final MxcImage mxcImage = tester.widget(mxcImageFinder);

          expect(mxcImage.uri, urlPreviewPresentation.imageUri);

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
            key: TwakeLinkPreviewController.twakeLinkPreviewItemKey,
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

          expect(
            find.byKey(LinkPreviewBuilder.imageDefaultKey),
            findsOneWidget,
          );

          expect(find.byType(MxcImage), findsNothing);
        },
      );
    },
  );
}
