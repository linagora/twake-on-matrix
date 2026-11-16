import 'dart:io';

import 'package:dartz/dartz.dart' hide State;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';
import 'package:twake_chat/di/global/get_it_initializer.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:twake_chat/presentation/model/chat/downloading_state_presentation_model.dart';
import 'package:twake_chat/utils/exception/downloading_exception.dart';
import 'package:twake_chat/utils/manager/download_manager/download_file_state.dart';
import 'package:twake_chat/utils/manager/download_manager/download_manager.dart';
import 'package:twake_chat/utils/responsive/responsive_utils.dart';
import 'package:twake_chat/widgets/mixins/download_file_on_mobile_mixin.dart';

import '../../fake_client.dart';

class _FakeDownloadManager implements DownloadManager {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _FileTile extends StatefulWidget {
  const _FileTile({required this.event});

  final Event event;

  @override
  State<_FileTile> createState() => _FileTileState();
}

class _FileTileState extends State<_FileTile>
    with DownloadFileOnMobileMixin<_FileTile> {
  @override
  Event get event => widget.event;

  @override
  Widget build(BuildContext context) => const SizedBox();
}

void main() {
  final en = lookupL10n(const Locale('en'));
  const pathProviderChannel = MethodChannel('plugins.flutter.io/path_provider');
  late Room room;
  late Directory tempDir;

  setUpAll(() async {
    final client = await getClient();
    room = Room(client: client, id: '!files:example.com');
    getIt.registerSingleton(ResponsiveUtils());
    getIt.registerSingleton<DownloadManager>(_FakeDownloadManager());
  });

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('download_on_mobile_test');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          pathProviderChannel,
          (_) async => tempDir.path,
        );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathProviderChannel, null);
    tempDir.deleteSync(recursive: true);
  });

  Future<_FileTileState> pumpTile(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: L10n.localizationsDelegates,
        supportedLocales: L10n.supportedLocales,
        home: Scaffold(
          body: _FileTile(
            event: Event(
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
            ),
          ),
        ),
      ),
    );
    return tester.state<_FileTileState>(find.byType(_FileTile));
  }

  testWidgets('resets the tile and explains a failed download', (tester) async {
    final tile = await pumpTile(tester);
    tile.downloadFileStateNotifier.value = const DownloadingPresentationState();

    tile.setupDownloadingProcess(
      Left(DownloadFileFailureState(exception: Exception('404'))),
    );
    await tester.pump();

    expect(
      tile.downloadFileStateNotifier.value,
      const NotDownloadPresentationState(),
    );
    expect(find.text(en.fileDownloadFailed), findsOneWidget);
  });

  testWidgets('stays silent when the user cancels', (tester) async {
    final tile = await pumpTile(tester);
    tile.downloadFileStateNotifier.value = const DownloadingPresentationState();

    tile.setupDownloadingProcess(
      Left(DownloadFileFailureState(exception: CancelDownloadingException())),
    );
    await tester.pump();

    expect(
      tile.downloadFileStateNotifier.value,
      const NotDownloadPresentationState(),
    );
    expect(find.text(en.fileDownloadFailed), findsNothing);
  });
}
