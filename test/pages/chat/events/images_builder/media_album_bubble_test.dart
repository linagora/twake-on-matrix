import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:twake_chat/pages/chat/events/images_builder/image_bubble.dart';
import 'package:twake_chat/pages/chat/events/images_builder/media_album_bubble.dart';
import 'package:twake_chat/pages/chat/events/images_builder/media_album_scope.dart';
import 'package:twake_chat/utils/manager/upload_manager/upload_manager.provider.dart';
import 'package:twake_chat/utils/manager/upload_manager/upload_manager.dart';
import 'package:twake_chat/utils/matrix_sdk_extensions/media_album_context_extension.dart';

import '../../../../lenient_database.dart';

class _FakeUploadManager implements UploadManager {
  @override
  Future<MatrixFile?> getMatrixFile(
    String eventId, {
    required Room room,
  }) async => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

/// Builds the events, the bubble under test and the fakes it reads.
class _Harness {
  late Room room;
  late _FakeUploadManager uploads;
  final pressed = <String>[];

  Future<void> init() async =>
      room = await getLenientRoom('!bubble:example.com');

  void reset() {
    uploads = _FakeUploadManager();
    pressed.clear();
  }

  Event image(String name, EventStatus status, int createdMs) => Event(
    senderId: '@a:example.com',
    type: 'm.room.message',
    room: room,
    eventId: 'Twake-$name-$createdMs',
    content: {'msgtype': 'm.image', 'body': '', 'filename': '$name.png'},
    originServerTs: DateTime.utc(2026, 11, 9),
    status: status,
  );

  /// One event per status, created in the order given.
  List<Event> events(List<EventStatus> statuses) => [
    for (var i = 0; i < statuses.length; i++)
      image(String.fromCharCode(65 + i), statuses[i], 1794209038793 + i * 50),
  ];

  Future<void> pumpAlbum(WidgetTester tester, List<Event> members) =>
      tester.pumpWidget(
        ProviderScope(
          retry: (_, _) => null,
          overrides: [uploadManagerProvider.overrideWithValue(uploads)],
          child: MaterialApp(
            localizationsDelegates: L10n.localizationsDelegates,
            supportedLocales: L10n.supportedLocales,
            home: Scaffold(
              body: Center(
                child: MediaAlbumPressScope<Event>(
                  onPressed: (event) => pressed.add(event.eventId),
                  child: MediaAlbumBubble<Event>(
                    members: members,
                    keyOf: (e) => e.transactionId ?? e.eventId,
                    tileBuilder: (_, e, {required width, required height}) =>
                        e.status.isSent
                        ? const SizedBox.expand()
                        : PendingImageTile(event: e),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

  Size tileSize(WidgetTester tester, Event e) => tester.getSize(
    find.byKey(ValueKey('album-tile-${e.transactionId ?? e.eventId}')),
  );

  Future<void> rowsOfTwo(WidgetTester tester) async {
    final e = events(List.filled(3, EventStatus.sending));
    await pumpAlbum(tester, e);

    expect(tileSize(tester, e[0]), tileSize(tester, e[1]));
    expect(
      tileSize(tester, e[2]).width,
      greaterThan(tileSize(tester, e[0]).width),
    );
    expect(tileSize(tester, e[2]).height, tileSize(tester, e[0]).height);
  }

  Future<void> spinnerWhileSending(WidgetTester tester) async {
    await pumpAlbum(tester, events(List.filled(2, EventStatus.sending)));

    expect(find.byType(CircularProgressIndicator), findsNWidgets(2));
  }

  /// Two tiles and the gap fill the grid, which is as wide as a single image.
  Future<void> gridIsAsWideAsAnImage(WidgetTester tester) async {
    final e = events(List.filled(2, EventStatus.sending));
    await pumpAlbum(tester, e);

    expect(tileSize(tester, e[0]).width * 2 + 2, 256);
    expect(tester.getSize(find.byType(MediaAlbumBubble<Event>)).width, 256);
  }

  /// A long-press menu opens for the image under the finger.
  Future<void> pressReportsTheTile(WidgetTester tester) async {
    final e = events(List.filled(3, EventStatus.sending));
    await pumpAlbum(tester, e);

    await tester.press(find.byKey(ValueKey('album-tile-${e[2].eventId}')));
    expect(pressed, [e[2].eventId]);
  }

  /// Reactions are drawn for every image, not only the leader.
  Future<void> eventsOfGivesEveryMember(WidgetTester tester) async {
    final e = events(List.filled(2, EventStatus.synced));
    List<Event>? found;
    await tester.pumpWidget(
      MediaAlbumScope<Event>(
        members: e,
        idOf: mediaAlbumEventId,
        child: Builder(
          builder: (context) {
            found = context.albumEventsOf(e.first);
            return const SizedBox();
          },
        ),
      ),
    );
    expect(found, e);
    final single = image('Z', EventStatus.synced, 1);
    await tester.pumpWidget(
      Builder(
        builder: (context) {
          found = context.albumEventsOf(single);
          return const SizedBox();
        },
      ),
    );
    expect(found, [single]);
  }

  /// The leader lays out the bubble, but the caption is on the last image.
  Future<void> leaderTakesTheAlbumCaption(WidgetTester tester) async {
    final e = events(List.filled(2, EventStatus.synced));
    final captioned = [
      e.first,
      Event(
        senderId: '@a:example.com',
        type: 'm.room.message',
        room: room,
        eventId: e.last.eventId,
        content: {'msgtype': 'm.image', 'body': 'Look', 'filename': 'B.png'},
        originServerTs: DateTime.utc(2026, 11, 9),
        status: EventStatus.synced,
      ),
    ];
    expect(await _hasCaption(tester, e.first, captioned), isTrue);
    expect(await _hasCaption(tester, e.first, e), isFalse);
    expect(await _hasCaption(tester, e.first, null), isFalse);
  }

  Future<bool?> _hasCaption(
    WidgetTester tester,
    Event asked,
    List<Event>? members,
  ) async {
    bool? found;
    final probe = Builder(
      builder: (context) {
        found = context.albumHasCaptionOrReply(asked);
        return const SizedBox();
      },
    );
    await tester.pumpWidget(
      members == null
          ? probe
          : MediaAlbumScope<Event>(
              members: members,
              idOf: mediaAlbumEventId,
              child: probe,
            ),
    );
    return found;
  }

  Future<void> scopeGivesLeaderOnly(WidgetTester tester) async {
    final e = events(List.filled(2, EventStatus.synced));

    expect(await _readScope(tester, e.first, e), e);
    expect(await _readScope(tester, e.last, e), isNull);
  }

  Future<List<Event>?> _readScope(
    WidgetTester tester,
    Event asked,
    List<Event> members,
  ) async {
    List<Event>? found;
    await tester.pumpWidget(
      MediaAlbumScope<Event>(
        members: members,
        idOf: mediaAlbumEventId,
        child: Builder(
          builder: (context) {
            found = context.albumMembersFor(asked);
            return const SizedBox();
          },
        ),
      ),
    );
    return found;
  }
}

void main() {
  final harness = _Harness();

  setUpAll(harness.init);
  setUp(harness.reset);

  testWidgets(
    'rows of two, and the last image of an odd count is full width',
    harness.rowsOfTwo,
  );
  testWidgets(
    'an image still sending shows a spinner',
    harness.spinnerWhileSending,
  );
  testWidgets(
    'the grid is as wide as a single image',
    harness.gridIsAsWideAsAnImage,
  );
  testWidgets(
    'pressing a tile reports that image',
    harness.pressReportsTheTile,
  );
  testWidgets(
    'every image of an album is listed for its reactions',
    harness.eventsOfGivesEveryMember,
  );
  testWidgets(
    'the leader is laid out with the caption of the last image',
    harness.leaderTakesTheAlbumCaption,
  );
  testWidgets(
    'the scope gives the members to the leader only',
    harness.scopeGivesLeaderOnly,
  );
}
