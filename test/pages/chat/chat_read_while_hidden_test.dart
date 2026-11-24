// Review of #3732 (jbrnzl): on macOS the window can be closed while the app
// stays alive, and the chat that was open stays mounted. A message that
// arrives then must not be marked read: the user has not seen it. Once the
// app is back in front, the room is marked read once, as when it is opened.
import 'dart:io' show File;

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show ProviderScope;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:just_audio/just_audio.dart';
import 'package:matrix/matrix.dart';
import 'package:matrix/src/models/timeline_chunk.dart';
import 'package:provider/provider.dart' show Provider;
import 'package:twake_chat/config/themes.dart';
import 'package:twake_chat/di/global/get_it_initializer.dart';
import 'package:twake_chat/domain/usecase/room/chat_get_pinned_events_interactor.dart';
import 'package:twake_chat/domain/usecase/room/delete_event_interactor.dart';
import 'package:twake_chat/domain/usecase/room/unblock_user_interactor.dart';
import 'package:twake_chat/pages/chat/chat_pinned_events/pinned_events_controller.dart';
import 'package:twake_chat/utils/manager/upload_manager/upload_manager.dart';
import 'package:twake_chat/utils/network_connection_service.dart';
import 'package:twake_chat/utils/search/search_engine.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:twake_chat/pages/chat/chat.dart';
import 'package:twake_chat/pages/chat/events/audio_message/audio_player_widget.dart';
import 'package:twake_chat/utils/responsive/responsive_utils.dart';
import 'package:twake_chat/widgets/matrix.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../../fake_client.dart';

const _roomId = '!room:example.org';
const _me = '@alice:example.org';

class _Client extends Client {
  _Client()
    : super(
        'chat-read-while-hidden-test',
        httpClient: FakeMatrixApi(),
        database: MockDatabase(),
      );

  late final _Room room = _Room(this);

  @override
  String? get userID => _me;

  @override
  Room? getRoomById(String id) => id == _roomId ? room : null;

  /// Threads on: the main timeline is read with a `main` threaded receipt.
  @override
  Future<void> postReceipt(
    String roomId,
    ReceiptType receiptType,
    String eventId, {
    String? threadId,
  }) => room.recordRead(eventId);

  /// Threads on: `m.fully_read` follows the receipt; nothing to record.
  @override
  Future<void> setReadMarker(
    String roomId, {
    String? mFullyRead,
    String? mRead,
    String? mReadPrivate,
  }) async {}
}

/// A joined room whose read markers are recorded instead of sent.
class _Room extends Room {
  _Room(Client client) : super(id: _roomId, client: client);

  /// Every read marker the app sent for this room.
  final readMarkers = <String?>[];

  /// Records the marker; after the round trip, the next sync brings the
  /// room back to no unread message, as the server would.
  @override
  Future<void> setReadMarker(String? eventId, {String? mRead, bool? public}) =>
      recordRead(eventId);

  Future<void> recordRead(String? eventId) async {
    readMarkers.add(eventId);
    await Future<void>.delayed(const Duration(milliseconds: 300));
    notificationCount = 0;
  }

  @override
  Future<Timeline> getTimeline({
    void Function(int index)? onChange,
    void Function(int index)? onRemove,
    void Function(int insertID)? onInsert,
    void Function()? onNewEvent,
    void Function()? onUpdate,
    String? eventContextId,
    int? limit = Room.defaultHistoryCount,
  }) async => Timeline(
    room: this,
    chunk: TimelineChunk(events: [_message(this, r'$first', 'Hello')]),
    onChange: onChange,
    onRemove: onRemove,
    onInsert: onInsert,
    onNewEvent: onNewEvent,
    onUpdate: onUpdate,
  );
}

Event _message(Room room, String id, String body) => Event(
  content: {'body': body, 'msgtype': MessageTypes.Text},
  type: EventTypes.Message,
  eventId: id,
  senderId: '@bob:example.org',
  originServerTs: DateTime(2026, 11, 23),
  room: room,
);

class _FakeMatrix extends Fake implements MatrixState {
  _FakeMatrix(this.client);

  @override
  final Client client;

  @override
  String? supportChatRoomId;

  @override
  File? wallpaper;

  @override
  AudioPlayer audioPlayer = _SilentPlayer();

  @override
  final voiceMessageEvent = ValueNotifier<Event?>(null);

  @override
  final currentAudioStatus = ValueNotifier(AudioPlayerStatus.notDownloaded);

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) =>
      '_FakeMatrix';
}

class _NoUploads implements UploadManager {
  @override
  Future<void> failInterruptedUploads(Iterable<Event> events) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _SilentPlayer extends Fake implements AudioPlayer {
  @override
  bool get playing => false;

  @override
  Future<void> stop() async {}

  @override
  Future<void> clearAudioSources() async {}
}

class _OnlineConnectivity extends Fake implements Connectivity {
  @override
  Stream<List<ConnectivityResult>> get onConnectivityChanged =>
      const Stream.empty();

  @override
  Future<List<ConnectivityResult>> checkConnectivity() async => const [
    ConnectivityResult.wifi,
  ];
}

void main() {
  late _Client client;

  setUp(() {
    VisibilityDetectorController.instance.updateInterval = Duration.zero;
    getIt
      ..registerSingleton(ResponsiveUtils())
      ..registerSingleton(NetworkConnectionService(_OnlineConnectivity()))
      ..registerFactory(ChatGetPinnedEventsInteractor.new)
      ..registerFactory(PinnedEventsController.new)
      ..registerFactory(DeleteEventInteractor.new)
      ..registerFactory(UnblockUserInteractor.new)
      ..registerSingleton<UploadManager>(_NoUploads())
      ..registerSingleton(const SearchEngine());
    client = _Client();
  });

  tearDown(() async {
    await getIt.reset();
  });

  void lifecycle(WidgetTester tester, AppLifecycleState state) =>
      tester.binding.handleAppLifecycleStateChanged(state);

  Future<void> openChat(WidgetTester tester) async {
    lifecycle(tester, AppLifecycleState.resumed);
    addTearDown(() => lifecycle(tester, AppLifecycleState.resumed));
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => const Chat(roomId: _roomId),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        child: Provider<MatrixState>.value(
          value: _FakeMatrix(client),
          child: Builder(
            builder: (context) => MaterialApp.router(
              routerConfig: router,
              theme: TwakeThemes.buildTheme(context, Brightness.light),
              localizationsDelegates: L10n.localizationsDelegates,
              supportedLocales: L10n.supportedLocales,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    client.room.readMarkers.clear();
  }

  /// Past the 2 s debounce of the mark-as-read on visibility and the 1 s
  /// rate limit of the room updates.
  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(seconds: 1));
    }
  }

  /// A message from Bob reaches the open chat, as a sync delivers it.
  Future<void> receiveMessage(WidgetTester tester) async {
    client.room.notificationCount = 1;
    client.onTimelineEvent.add(
      _message(client.room, r'$new', 'Are you there?'),
    );
    await settle(tester);
  }

  /// macOS: the user closes the window, the app stays in the Dock.
  Future<void> closeWindow(WidgetTester tester) async {
    lifecycle(tester, AppLifecycleState.inactive);
    lifecycle(tester, AppLifecycleState.hidden);
    await tester.pump();
  }

  /// The user brings the window back (Dock icon, notification).
  Future<void> reopenWindow(WidgetTester tester) async {
    lifecycle(tester, AppLifecycleState.inactive);
    lifecycle(tester, AppLifecycleState.resumed);
    await settle(tester);
  }

  testWidgets('a message that arrives in the open chat is marked read', (
    tester,
  ) async {
    await openChat(tester);

    await receiveMessage(tester);

    expect(client.room.readMarkers, [r'$new']);
  });

  testWidgets('a message that arrives while the window is closed is not '
      'marked read', (tester) async {
    await openChat(tester);
    await closeWindow(tester);

    await receiveMessage(tester);

    expect(client.room.readMarkers, isEmpty);
  });

  testWidgets('a message that arrives while another app is in front is not '
      'marked read', (tester) async {
    await openChat(tester);
    lifecycle(tester, AppLifecycleState.inactive);

    await receiveMessage(tester);

    expect(client.room.readMarkers, isEmpty);
  });

  testWidgets('a message that arrived while the window was closed is marked '
      'read once the window reopens', (tester) async {
    await openChat(tester);
    await closeWindow(tester);
    await receiveMessage(tester);
    // Only what reopening sends; what the closed window sent is the test
    // above.
    client.room.readMarkers.clear();

    await reopenWindow(tester);

    expect(client.room.readMarkers, [r'$new']);
  });

  testWidgets('reopening the window on a room already read sends no read '
      'marker', (tester) async {
    await openChat(tester);
    await closeWindow(tester);

    await reopenWindow(tester);

    expect(client.room.readMarkers, isEmpty);
  });
}
