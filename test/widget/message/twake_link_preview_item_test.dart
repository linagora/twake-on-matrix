import 'package:dartz/dartz.dart';
import 'package:fluffychat/domain/app_state/preview_url/get_preview_url_success.dart';
import 'package:fluffychat/domain/model/media/url_preview.dart';
import 'package:fluffychat/domain/usecase/preview_url/get_preview_url_interactor.dart';
import 'package:fluffychat/presentation/model/media/url_preview_presentation.dart';
import 'package:fluffychat/widgets/mxc_image.dart';
import 'package:fluffychat/widgets/twake_components/twake_preview_link/twake_link_preview.dart';
import 'package:fluffychat/widgets/twake_components/twake_preview_link/twake_link_preview_item.dart';
import 'package:fluffychat/widgets/twake_components/twake_preview_link/twake_link_preview_item_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'twake_link_preview_item_test.mocks.dart';

@GenerateNiceMocks([MockSpec<GetPreviewURLInteractor>()])
void main() {
  group('[WIDGET TEST] - LinkPreviewBuilder content\n', () {
    testWidgets('GIVEN no image uri\n'
        'AND no image width and height\n'
        'AND only title and description\n'
        'THEN not display MxcImage widget', (WidgetTester tester) async {
      final urlPreviewPresentation = UrlPreviewPresentation(
        title: 'Test Title',
        description: 'Test Description',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LinkPreviewBuilder(
              urlPreviewPresentation: urlPreviewPresentation,
            ),
          ),
        ),
      );

      expect(find.byKey(LinkPreviewBuilder.imageDefaultKey), findsOneWidget);

      final paddingTitleFind = find.byKey(LinkPreviewBuilder.paddingTitleKey);
      final paddingSubtitleFind = find.byKey(
        LinkPreviewBuilder.paddingSubtitleKey,
      );

      final Padding paddingTitleWidget = tester.widget(paddingTitleFind);
      final Padding paddingSubtitleWidget = tester.widget(paddingSubtitleFind);

      expect(
        paddingTitleWidget.padding,
        TwakeLinkPreviewItemStyle.paddingTitle,
      );

      expect(
        paddingSubtitleWidget.padding,
        TwakeLinkPreviewItemStyle.paddingSubtitle,
      );

      expect(find.byKey(LinkPreviewBuilder.titleKey), findsOneWidget);
      expect(find.byKey(LinkPreviewBuilder.subtitleKey), findsOneWidget);

      final Text titleTextWidget = tester.widget(
        find.byKey(LinkPreviewBuilder.titleKey),
      );
      final Text subtitleTextWidget = tester.widget(
        find.byKey(LinkPreviewBuilder.subtitleKey),
      );

      expect(titleTextWidget.data, urlPreviewPresentation.title);
      expect(subtitleTextWidget.data, urlPreviewPresentation.description);

      expect(find.byType(MxcImage), findsNothing);
    });

    testWidgets('GIVEN an image uri\n'
        'AND no image width and height\n'
        'AND only title and description\n'
        'THEN not display MxcImage widget', (WidgetTester tester) async {
      final urlPreviewPresentation = UrlPreviewPresentation(
        imageUri: Uri.parse('https://test.com'),
        title: 'Test Title',
        description: 'Test Description',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LinkPreviewBuilder(
              urlPreviewPresentation: urlPreviewPresentation,
            ),
          ),
        ),
      );

      expect(find.byKey(LinkPreviewBuilder.imageDefaultKey), findsOneWidget);

      final paddingTitleFind = find.byKey(LinkPreviewBuilder.paddingTitleKey);
      final paddingSubtitleFind = find.byKey(
        LinkPreviewBuilder.paddingSubtitleKey,
      );

      final Padding paddingTitleWidget = tester.widget(paddingTitleFind);
      final Padding paddingSubtitleWidget = tester.widget(paddingSubtitleFind);

      expect(
        paddingTitleWidget.padding,
        TwakeLinkPreviewItemStyle.paddingTitle,
      );

      expect(
        paddingSubtitleWidget.padding,
        TwakeLinkPreviewItemStyle.paddingSubtitle,
      );

      final Text titleTextWidget = tester.widget(
        find.byKey(LinkPreviewBuilder.titleKey),
      );
      final Text subtitleTextWidget = tester.widget(
        find.byKey(LinkPreviewBuilder.subtitleKey),
      );

      expect(titleTextWidget.data, urlPreviewPresentation.title);
      expect(subtitleTextWidget.data, urlPreviewPresentation.description);

      expect(find.byType(MxcImage), findsNothing);
    });

    testWidgets('GIVEN an image uri\n'
        'AND an image width is null\n'
        'AND only title and description\n'
        'THEN not display MxcImage widget', (WidgetTester tester) async {
      final urlPreviewPresentation = UrlPreviewPresentation(
        title: 'Test Title',
        description: 'Test Description',
        imageUri: Uri.parse('https://test.com'),
        imageHeight: 123,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LinkPreviewBuilder(
              urlPreviewPresentation: urlPreviewPresentation,
            ),
          ),
        ),
      );

      expect(find.byKey(LinkPreviewBuilder.imageDefaultKey), findsOneWidget);
      expect(find.byType(MxcImage), findsNothing);
    });

    testWidgets('GIVEN an image response\n'
        'AND an image height is null\n'
        'AND only title and description\n'
        'THEN not display MxcImage widget', (WidgetTester tester) async {
      final urlPreviewPresentation = UrlPreviewPresentation(
        title: 'Test Title',
        description: 'Test Description',
        imageUri: Uri.parse('https://test.com'),
        imageWidth: 123,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LinkPreviewBuilder(
              urlPreviewPresentation: urlPreviewPresentation,
            ),
          ),
        ),
      );

      expect(find.byKey(LinkPreviewBuilder.imageDefaultKey), findsOneWidget);
      expect(find.byType(MxcImage), findsNothing);
    });

    testWidgets('GIVEN an image response\n'
        'AND an image height and width are not null\n'
        'AND only title and description\n'
        'THEN display MxcImage widget', (WidgetTester tester) async {
      final urlPreviewPresentation = UrlPreviewPresentation(
        title: 'Test Title',
        description: 'Test Description',
        imageUri: Uri.parse('https://test.com'),
        imageWidth: 123,
        imageHeight: 201,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LinkPreviewBuilder(
              urlPreviewPresentation: urlPreviewPresentation,
            ),
          ),
        ),
      );

      final clipRRectMxcImage = find.byKey(LinkPreviewBuilder.clipRRectKey);

      expect(clipRRectMxcImage, findsOneWidget);

      final ClipRRect clipRRectWidget = tester.widget(clipRRectMxcImage);

      expect(
        clipRRectWidget.borderRadius,
        equals(
          const BorderRadius.vertical(
            top: Radius.circular(TwakeLinkPreviewItemStyle.radiusBorder),
            bottom: Radius.circular(TwakeLinkPreviewItemStyle.radiusBorder),
          ),
        ),
      );

      final mxcImageFinder = find.byKey(LinkPreviewBuilder.mxcImageKey);

      expect(mxcImageFinder, findsOneWidget);

      final MxcImage mxcImage = tester.widget(mxcImageFinder);

      expect(mxcImage.uri, urlPreviewPresentation.imageUri);
      expect(mxcImage.fit, BoxFit.cover);
      expect(mxcImage.isThumbnail, false);
    });
  });

  group('[WIDGET TEST] - TwakeLinkPreviewItem ownMessage color\n', () {
    late MockGetPreviewURLInteractor mockInteractor;

    setUp(() {
      mockInteractor = MockGetPreviewURLInteractor();
      when(
        mockInteractor.execute(
          uri: anyNamed('uri'),
          preferredPreviewTime: anyNamed('preferredPreviewTime'),
        ),
      ).thenAnswer(
        (_) => Stream.value(
          Right(
            GetPreviewUrlSuccess(
              urlPreview: UrlPreview(
                title: 'Test Title',
                description: 'Test Description',
              ),
            ),
          ),
        ),
      );
      GetIt.instance.registerSingleton<GetPreviewURLInteractor>(mockInteractor);
    });

    tearDown(() {
      GetIt.instance.unregister<GetPreviewURLInteractor>();
    });

    testWidgets('GIVEN ownMessage is true\n'
        'THEN container uses primaryContainer color', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TwakeLinkPreviewItem(
              key: TwakeLinkPreview.twakeLinkPreviewItemKey,
              ownMessage: true,
              previewLink: 'https://test.com',
            ),
          ),
        ),
      );

      await tester.pump();

      final bodyFinder = find.byKey(TwakeLinkPreviewItem.linkPreviewBodyKey);

      expect(bodyFinder, findsOneWidget);

      final Container body = tester.widget(bodyFinder);
      final ShapeDecoration decoration = body.decoration! as ShapeDecoration;

      expect(decoration.color, LinagoraSysColors.material().primaryContainer);

      expect(decoration.shape, isNotNull);

      final RoundedRectangleBorder shape =
          decoration.shape as RoundedRectangleBorder;

      expect(
        shape.borderRadius,
        BorderRadius.circular(TwakeLinkPreviewItemStyle.radiusBorder),
      );
    });

    testWidgets('GIVEN ownMessage is false\n'
        'THEN container uses onSurface color with opacity', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TwakeLinkPreviewItem(
              key: TwakeLinkPreview.twakeLinkPreviewItemKey,
              ownMessage: false,
              previewLink: 'https://test.com',
            ),
          ),
        ),
      );

      await tester.pump();

      final bodyFinder = find.byKey(TwakeLinkPreviewItem.linkPreviewBodyKey);

      expect(bodyFinder, findsOneWidget);

      final Container body = tester.widget(bodyFinder);
      final ShapeDecoration decoration = body.decoration! as ShapeDecoration;

      expect(
        decoration.color,
        LinagoraSysColors.material().onSurface.withOpacity(0.08),
      );
    });
  });
}
