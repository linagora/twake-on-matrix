import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';
import 'package:twake_chat/app_state/failure.dart';
import 'package:twake_chat/app_state/success.dart';
import 'package:twake_chat/di/global/get_it_initializer.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:twake_chat/presentation/mixins/save_file_to_twake_downloads_folder_mixin.dart';
import 'package:twake_chat/utils/dialog/downloading_file_dialog.dart';
import 'package:twake_chat/utils/exception/downloading_exception.dart';
import 'package:twake_chat/utils/manager/download_manager/download_file_state.dart';
import 'package:twake_chat/utils/manager/download_manager/download_manager.dart';
import 'package:twake_chat/utils/responsive/responsive_utils.dart';

import '../../fake_client.dart';

class _FakeDownloadManager implements DownloadManager {
  StreamController<Either<Failure, Success>> controller =
      StreamController<Either<Failure, Success>>.broadcast();

  @override
  Future<void> download({
    required Event event,
    bool getThumbnail = false,
    bool isFirstPriority = false,
  }) async {}

  @override
  Stream<Either<Failure, Success>>? getDownloadStateStream(String eventId) =>
      controller.stream;

  @override
  Future<void> cancelDownload(String eventId) async {
    controller.add(
      Left(DownloadFileFailureState(exception: CancelDownloadingException())),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Saver with SaveFileToTwakeAndroidDownloadsFolderMixin {}

void main() {
  final en = lookupL10n(const Locale('en'));
  late Room room;
  late _FakeDownloadManager downloadManager;

  setUpAll(() async {
    final client = await getClient();
    room = Room(client: client, id: '!files:example.com');
    getIt.registerSingleton(ResponsiveUtils());
  });

  setUp(() {
    downloadManager = _FakeDownloadManager();
    getIt.registerSingleton<DownloadManager>(downloadManager);
  });

  tearDown(() {
    getIt.unregister<DownloadManager>();
  });

  Event fileEvent() => Event(
    type: EventTypes.Message,
    content: {
      'msgtype': MessageTypes.File,
      'body': 'report.pdf',
      'url': 'mxc://example.com/gone',
    },
    eventId: '\$file',
    senderId: '@alice:example.com',
    originServerTs: DateTime(2026, 11, 12),
    room: room,
  );

  Future<void> startDownload(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: L10n.localizationsDelegates,
        supportedLocales: L10n.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => _Saver().handleWhenFileHaveNotDownloaded(
                fileEvent(),
                context,
              ),
              child: const Text('save'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('save'));
    await tester.pump();
    expect(find.byType(DownloadingFileDialog), findsOneWidget);
  }

  testWidgets('closes the dialog and explains the failure', (tester) async {
    await startDownload(tester);

    downloadManager.controller.add(
      Left(DownloadFileFailureState(exception: Exception('404'))),
    );
    await tester.pumpAndSettle();

    expect(find.byType(DownloadingFileDialog), findsNothing);
    expect(find.text(en.fileDownloadFailed), findsOneWidget);
    expect(find.text('save'), findsOneWidget);
  });

  testWidgets('stays silent when the user cancels', (tester) async {
    await startDownload(tester);

    await tester.tap(find.text(en.cancel));
    await tester.pumpAndSettle();

    expect(find.byType(DownloadingFileDialog), findsNothing);
    expect(find.text(en.fileDownloadFailed), findsNothing);
    expect(find.text('save'), findsOneWidget);
  });
}
