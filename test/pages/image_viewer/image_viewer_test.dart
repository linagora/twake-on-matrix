import 'dart:async';

import 'package:dartz/dartz.dart' hide State;
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';
import 'package:twake_chat/app_state/failure.dart';
import 'package:twake_chat/app_state/success.dart';
import 'package:twake_chat/di/global/get_it_initializer.dart';
import 'package:twake_chat/domain/app_state/download/download_file_state.dart';
import 'package:twake_chat/domain/usecase/room/download_media_file_interactor.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:twake_chat/pages/image_viewer/image_viewer.dart';
import 'package:twake_chat/utils/responsive/responsive_utils.dart';

class _FakeEvent extends Fake implements Event {
  @override
  String get eventId => r'$image';

  @override
  Map<String, Object?> get content => {
    'info': {'mimetype': 'image/png'},
  };
}

/// Hands out one controllable stream per `execute` call.
class _FakeDownloadMediaFileInteractor extends DownloadMediaFileInteractor {
  final mainDownloads = <StreamController<Either<Failure, Success>>>[];
  final thumbnailDownloads = <StreamController<Either<Failure, Success>>>[];

  @override
  Stream<Either<Failure, Success>> execute({
    required Event event,
    bool getThumbnail = false,
  }) {
    final controller = StreamController<Either<Failure, Success>>();
    (getThumbnail ? thumbnailDownloads : mainDownloads).add(controller);
    return controller.stream;
  }
}

void main() {
  late _FakeDownloadMediaFileInteractor interactor;

  setUpAll(() {
    if (!getIt.isRegistered<ResponsiveUtils>()) {
      getIt.registerSingleton(ResponsiveUtils());
    }
  });

  setUp(() {
    interactor = _FakeDownloadMediaFileInteractor();
    getIt.registerSingleton<DownloadMediaFileInteractor>(interactor);
  });

  tearDown(() => getIt.unregister<DownloadMediaFileInteractor>());

  Future<void> pumpViewer(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: L10n.localizationsDelegates,
        supportedLocales: L10n.supportedLocales,
        home: ImageViewer(event: _FakeEvent(), showAppBar: false),
      ),
    );
    await tester.pump();
  }

  Future<void> failMainDownload(WidgetTester tester) async {
    interactor.mainDownloads.last.add(
      const Left(DownloadMediaFileFailure(exception: 'offline')),
    );
    await tester.pump();
  }

  testWidgets('GIVEN the main download failed '
      'WHEN the broken-image icon is tapped '
      'THEN the main download starts again and the loader is back', (
    tester,
  ) async {
    await pumpViewer(tester);
    await failMainDownload(tester);
    expect(find.byIcon(Icons.broken_image_outlined), findsOneWidget);

    await tester.tap(find.byIcon(Icons.broken_image_outlined));
    // The viewer also listens for double taps, so a single tap only resolves
    // once the double-tap window has passed.
    await tester.pump(kDoubleTapTimeout);

    expect(interactor.mainDownloads, hasLength(2));
    expect(interactor.thumbnailDownloads, hasLength(1));
    expect(interactor.mainDownloads.first.hasListener, isFalse);
    expect(interactor.mainDownloads.last.hasListener, isTrue);
    expect(find.byIcon(Icons.broken_image_outlined), findsNothing);
    expect(find.byType(CupertinoActivityIndicator), findsOneWidget);

    await tester.pump(const Duration(seconds: 5));
  });

  testWidgets('GIVEN the main and thumbnail downloads are running '
      'WHEN the viewer is disposed '
      'THEN both subscriptions are cancelled', (tester) async {
    await pumpViewer(tester);
    expect(interactor.mainDownloads.single.hasListener, isTrue);
    expect(interactor.thumbnailDownloads.single.hasListener, isTrue);

    await tester.pumpWidget(const SizedBox());

    expect(interactor.mainDownloads.single.hasListener, isFalse);
    expect(interactor.thumbnailDownloads.single.hasListener, isFalse);
  });
}
