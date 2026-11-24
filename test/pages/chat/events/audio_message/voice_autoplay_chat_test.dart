// #2796: when a voice message ends, the chat plays the next one if it is a
// voice message too.
import 'dart:io' show File;

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'
    show ProviderContainer, ProviderScope;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:just_audio/just_audio.dart';
import 'package:matrix/matrix.dart';
import 'package:matrix/src/models/timeline_chunk.dart';
import 'package:provider/provider.dart' show Provider;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:twake_chat/config/themes.dart';
import 'package:twake_chat/data/voice_message/repositories/voice_message_repository.provider.dart';
import 'package:twake_chat/di/global/get_it_initializer.dart';
import 'package:twake_chat/domain/usecase/room/chat_get_pinned_events_interactor.dart';
import 'package:twake_chat/domain/usecase/room/delete_event_interactor.dart';
import 'package:twake_chat/domain/usecase/room/unblock_user_interactor.dart';
import 'package:twake_chat/domain/voice_message/repositories/voice_message_repository.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:twake_chat/pages/chat/chat.dart';
import 'package:twake_chat/pages/chat/chat_pinned_events/pinned_events_controller.dart';
import 'package:twake_chat/pages/chat/events/audio_message/audio_player_widget.dart';
import 'package:twake_chat/pages/chat/events/audio_message/voice_autoplay_controller.dart';
import 'package:twake_chat/utils/manager/upload_manager/upload_manager.dart';
import 'package:twake_chat/utils/network_connection_service.dart';
import 'package:twake_chat/utils/responsive/responsive_utils.dart';
import 'package:twake_chat/utils/search/search_engine.dart';
import 'package:twake_chat/widgets/file_widget/circular_loading_download_widget.dart';
import 'package:twake_chat/widgets/matrix.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../../../../fake_client.dart';

const _roomId = '!room:example.org';

class _Client extends Client {
  _Client()
    : super(
        'voice-autoplay-test',
        httpClient: FakeMatrixApi(),
        database: MockDatabase(),
      );

  late final _Room room = _Room(this);

  @override
  String? get userID => '@alice:example.org';

  @override
  Room? getRoomById(String id) => id == _roomId ? room : null;
}

class _Room extends Room {
  _Room(Client client) : super(id: _roomId, client: client);

  late final events = [_voice(this, 'v2'), _voice(this, 'v1')];

  @override
  Future<Event?> getEventById(String eventID) async =>
      events.where((e) => e.eventId == eventID).firstOrNull;

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
    chunk: TimelineChunk(events: events),
    onChange: onChange,
    onRemove: onRemove,
    onInsert: onInsert,
    onNewEvent: onNewEvent,
    onUpdate: onUpdate,
  );
}

Event _voice(Room room, String id) => Event(
  content: {
    'body': 'voice_message_$id.ogg',
    'msgtype': MessageTypes.Audio,
    'info': {'mimetype': 'audio/ogg', 'size': 1000},
    'org.matrix.msc1767.audio': {
      'duration': 3000,
      'waveform': [1, 512, 1024],
    },
    'org.matrix.msc3245.voice': <String, Object?>{},
  },
  type: EventTypes.Message,
  eventId: id,
  senderId: '@bob:example.org',
  originServerTs: DateTime(2026, 11, 24),
  room: room,
);

class _Repository implements VoiceMessageRepository {
  @override
  Future<String?> nextVoiceMessageId({
    required String roomId,
    required String eventId,
  }) async => eventId == 'v1' ? 'v2' : null;
}

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

  @override
  Future<void> dispose() async {}

  @override
  Stream<Duration> get positionStream => const Stream.empty();

  @override
  Stream<PlayerState> get playerStateStream => const Stream.empty();

  @override
  Stream<double> get speedStream => const Stream.empty();

  @override
  Duration get position => Duration.zero;

  @override
  Duration? get duration => null;

  @override
  double get speed => 1;
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
  late _FakeMatrix matrix;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockStreamHandler(
          const EventChannel('flutter_keyboard_visibility'),
          MockStreamHandler.inline(onListen: (_, _) {}),
        );
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
    matrix = _FakeMatrix(client);
  });

  tearDown(() async {
    await getIt.reset();
  });

  Future<ProviderContainer> openChat(WidgetTester tester) async {
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
        overrides: [
          voiceMessageRepositoryProvider.overrideWithValue(_Repository()),
        ],
        child: Provider<MatrixState>.value(
          value: matrix,
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
    return ProviderScope.containerOf(tester.element(find.byType(Chat)));
  }

  /// Past the timers the chat screen leaves behind (debounces, typing).
  Future<void> closeChat(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 5));
  }

  Finder bubble(String eventId) => find.byWidgetPredicate(
    (widget) => widget is AudioPlayerWidget && widget.event.eventId == eventId,
  );

  Future<void> endVoiceMessage(
    WidgetTester tester,
    ProviderContainer container,
    String eventId,
  ) async {
    await tester.runAsync(
      () => container
          .read(voiceAutoplayControllerProvider(_roomId).notifier)
          .voiceMessageEnded(eventId),
    );
    // The download of the next one runs outside the fake clock.
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pump();
  }

  testWidgets('the next voice message starts when one ends', (tester) async {
    final container = await openChat(tester);
    expect(bubble('v1'), findsOneWidget);
    expect(bubble('v2'), findsOneWidget);

    await endVoiceMessage(tester, container, 'v1');

    expect(matrix.voiceMessageEvent.value?.eventId, 'v2');
    expect(
      find.descendant(
        of: bubble('v2'),
        matching: find.byType(CircularLoadingDownloadWidget),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: bubble('v1'),
        matching: find.byType(CircularLoadingDownloadWidget),
      ),
      findsNothing,
    );
    await closeChat(tester);
  });

  testWidgets('nothing starts after the last voice message', (tester) async {
    final container = await openChat(tester);

    await endVoiceMessage(tester, container, 'v2');

    expect(matrix.voiceMessageEvent.value, isNull);
    expect(find.byType(CircularLoadingDownloadWidget), findsNothing);
    await closeChat(tester);
  });

  testWidgets('the next one does not start over an audio the user started', (
    tester,
  ) async {
    final container = await openChat(tester);
    final other = _voice(client.room, 'other');
    matrix.voiceMessageEvent.value = other;

    await endVoiceMessage(tester, container, 'v1');

    expect(matrix.voiceMessageEvent.value, same(other));
    await closeChat(tester);
  });
}
