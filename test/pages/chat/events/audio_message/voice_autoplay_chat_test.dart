// #2796: when a voice message ends, the chat plays the next one if it is a
// voice message too.
import 'dart:async';
import 'dart:convert';
import 'dart:io' show Directory, File;

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'
    show ProviderContainer, ProviderScope;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';
import 'package:matrix/matrix.dart';
import 'package:matrix/src/models/timeline_chunk.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:provider/provider.dart' show Provider;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:twake_chat/config/themes.dart';
import 'package:twake_chat/data/voice_message/repositories/voice_message_repository.provider.dart';
import 'package:twake_chat/domain/drive/entities/drive_config.dart';
import 'package:twake_chat/providers/active_matrix_client_provider.dart';
import 'package:twake_chat/providers/drive_config_provider.dart';
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
import 'package:twake_chat/utils/platform_infos.dart';
import 'package:twake_chat/utils/responsive/responsive_utils.dart';
import 'package:twake_chat/utils/search/search_engine.dart';
import 'package:twake_chat/widgets/file_widget/circular_loading_download_widget.dart';
import 'package:twake_chat/widgets/matrix.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../../../../fake_client.dart';

const _roomId = '!room:example.org';

/// A message the chat does not show, as after a jump: only the store knows
/// what follows it.
const _notShown = 'not-shown';

/// Fails media downloads, or serves them once [media] completes; the rest as
/// [FakeMatrixApi].
class _Api extends http.BaseClient {
  final _api = FakeMatrixApi();
  Completer<void>? media;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    if (!request.url.path.contains('/media/download/')) {
      return _api.send(request);
    }
    final media = this.media;
    if (media == null) {
      return http.StreamedResponse(
        Stream.value(utf8.encode('{"errcode":"M_NOT_FOUND"}')),
        404,
      );
    }
    await media.future;
    return http.StreamedResponse(Stream.value([1, 2, 3]), 200);
  }
}

class _FakePathProvider extends PathProviderPlatform {
  @override
  Future<String?> getTemporaryPath() async => Directory.systemTemp.path;
}

class _Client extends Client {
  _Client(this.api)
    : super('voice-autoplay-test', httpClient: api, database: MockDatabase()) {
    homeserver = Uri.parse('https://fakeserver.notexisting');
  }

  final _Api api;

  late final _Room room = _Room(this);

  @override
  String? get userID => '@alice:example.org';

  @override
  bool isLogged() => true;

  @override
  Room? getRoomById(String id) => id == _roomId ? room : null;
}

class _Room extends Room {
  _Room(Client client) : super(id: _roomId, client: client);

  late final events = [_voice(this, 'v2'), _voice(this, 'v1')];

  /// Holds the lookup of the next message, as a slow store would.
  Completer<void>? lookup;

  @override
  Future<Event?> getEventById(String eventID) async {
    await lookup?.future;
    return events.where((e) => e.eventId == eventID).firstOrNull;
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
    'url': 'mxc://example.org/$id',
    'body': 'voice_message_$id.ogg',
    'msgtype': MessageTypes.Audio,
    'info': {'mimetype': 'audio/ogg'},
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
    String? threadRootId,
  }) async => eventId == _notShown ? 'v2' : null;
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
      // The voice recorder of the mobile composer.
      ..setMockMethodCallHandler(
        const MethodChannel('com.llfbandit.record/messages'),
        (_) async => null,
      )
      ..setMockStreamHandler(
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
    // The mobile path, on any host: the voice bubble shows on mobile.
    PlatformInfos.isTestingForIOS = true;
    PathProviderPlatform.instance = _FakePathProvider();
    client = _Client(_Api());
    matrix = _FakeMatrix(client);
  });

  tearDown(() async {
    PlatformInfos.isTestingForIOS = false;
    await getIt.reset();
  });

  late GoRouter router;

  Future<ProviderContainer> openChat(WidgetTester tester) async {
    router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => const Chat(roomId: _roomId),
        ),
        GoRoute(path: '/other', builder: (_, _) => const SizedBox()),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          activeMatrixClientProvider.overrideWithValue(client),
          voiceMessageRepositoryProvider.overrideWithValue(_Repository()),
          driveConfigProvider.overrideWithValue(
            const DriveConfig(ssoUrl: '', ssoClientId: ''),
          ),
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
    await tester.runAsync(() async {
      container
          .read(voiceAutoplayControllerProvider(_roomId, null).notifier)
          .voiceMessageEnded(eventId);
    });
    // The download of the next one runs outside the fake clock.
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pump();
  }

  testWidgets('the next voice message starts when one ends', (tester) async {
    final container = await openChat(tester);
    client.api.media = Completer();
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

  testWidgets('a failed download leaves the next one ready to retry', (
    tester,
  ) async {
    final container = await openChat(tester);

    await endVoiceMessage(tester, container, 'v1');

    expect(matrix.voiceMessageEvent.value, isNull);
    expect(matrix.currentAudioStatus.value, AudioPlayerStatus.notDownloaded);
    await closeChat(tester);
  });

  testWidgets('a run that starts during the lookup drops the queued one', (
    tester,
  ) async {
    final container = await openChat(tester);
    client.room.lookup = Completer();
    client.api.media = Completer();
    await endVoiceMessage(tester, container, 'v1');

    await endVoiceMessage(tester, container, 'v2');
    client.room.lookup!.complete();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pump();

    expect(matrix.voiceMessageEvent.value, isNull);
    await closeChat(tester);
  });

  testWidgets('a failed lookup of the next one plays nothing', (tester) async {
    final container = await openChat(tester);
    client.room.lookup = Completer();
    await endVoiceMessage(tester, container, 'v1');

    client.room.lookup!.completeError(Exception('store closed'));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pump();

    expect(matrix.voiceMessageEvent.value, isNull);
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

  testWidgets('nothing starts behind a screen opened over the chat', (
    tester,
  ) async {
    final container = await openChat(tester);
    unawaited(router.push('/other'));
    await tester.pumpAndSettle();
    expect(find.byType(Chat, skipOffstage: false), findsOneWidget);

    await endVoiceMessage(tester, container, 'v1');

    expect(matrix.voiceMessageEvent.value, isNull);
    await closeChat(tester);
  });

  testWidgets('nothing starts once the chat is left during the lookup', (
    tester,
  ) async {
    final container = await openChat(tester);
    final keepAlive = container.listen(
      voiceAutoplayControllerProvider(_roomId, null),
      (_, _) {},
    );
    addTearDown(keepAlive.close);
    client.room.lookup = Completer();
    await endVoiceMessage(tester, container, 'v1');

    router.go('/other');
    await tester.pumpAndSettle();
    expect(find.byType(Chat), findsNothing);
    client.room.lookup!.complete();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pump();

    expect(matrix.voiceMessageEvent.value, isNull);
    await closeChat(tester);
  });

  // Opening a screen keeps the chat mounted, as leaving it on mobile keeps the
  // shared player as it is.
  testWidgets('nothing starts once a screen opens over the chat during the '
      'download', (tester) async {
    final container = await openChat(tester);
    final keepAlive = container.listen(
      voiceAutoplayControllerProvider(_roomId, null),
      (_, _) {},
    );
    addTearDown(keepAlive.close);
    final player = matrix.audioPlayer;
    client.api.media = Completer();
    await endVoiceMessage(tester, container, 'v1');
    expect(matrix.voiceMessageEvent.value?.eventId, 'v2');

    unawaited(router.push('/other'));
    await tester.pumpAndSettle();
    client.api.media!.complete();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 300)),
    );
    await tester.pump();

    expect(matrix.voiceMessageEvent.value, isNull);
    expect(matrix.audioPlayer, same(player));
    await closeChat(tester);
  });

  testWidgets('the store gives the next one of a message the chat does not '
      'show', (tester) async {
    final container = await openChat(tester);
    client.api.media = Completer();

    await endVoiceMessage(tester, container, _notShown);

    expect(matrix.voiceMessageEvent.value?.eventId, 'v2');
    await closeChat(tester);
  });
}
