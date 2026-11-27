import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';
import 'package:scroll_to_index/scroll_to_index.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:twake_chat/config/setting_keys.dart';
import 'package:twake_chat/di/global/get_it_initializer.dart';
import 'package:twake_chat/pages/chat/chat.dart';
import 'package:twake_chat/pages/chat/chat_event_list.dart';
import 'package:twake_chat/utils/matrix_sdk_extensions/filtered_timeline_extension.dart';
import 'package:twake_chat/utils/responsive/responsive_utils.dart';

import '../../fake_client.dart';

// Review of #3842: who stopped reading at each own message is worked out for
// the whole timeline on every build of the chat. With the ticks (the default)
// nobody shows it, so the chat must not read the receipts for it at all.

class _Client extends Client {
  _Client()
    : super(
        'chat-event-list-seen-style-test',
        httpClient: FakeMatrixApi(),
        database: MockDatabase(),
      );

  @override
  String? get userID => '@me:example.org';
}

/// A room that counts how often its read receipts are looked at.
class _CountingRoom extends Room {
  _CountingRoom(Client client) : super(id: '!room:example.org', client: client);

  int receiptReads = 0;

  LatestReceiptState _receiptState = LatestReceiptState.empty();

  @override
  LatestReceiptState get receiptState {
    receiptReads++;
    return _receiptState;
  }

  @override
  set receiptState(LatestReceiptState value) => _receiptState = value;
}

class _Timeline extends Fake implements Timeline {
  @override
  List<Event> get events => const [];

  @override
  bool isRequestingHistory = false;

  @override
  bool isRequestingFuture = false;

  @override
  bool get canRequestHistory => false;

  @override
  bool get canRequestFuture => false;
}

/// An open chat with messages to list: none drawn yet, so nothing but the
/// list itself can read the receipts.
class _Chat extends Fake implements ChatController {
  _Chat(this.room);

  @override
  final Room room;

  @override
  final Timeline timeline = _Timeline();

  @override
  final AutoScrollController scrollController = AutoScrollController();

  @override
  final ValueNotifier<bool> showScrollDownButtonNotifier = ValueNotifier(false);

  @override
  List<Event> get eventsToDisplay => const [];

  @override
  bool get isEmptySupportChat => false;

  @override
  bool get hasNoMessageEvents => false;

  @override
  bool get selectMode => false;

  @override
  double? jumpListCacheExtent;

  @override
  String? unreadReceivedMessageLocation;

  @override
  bool isInViewPortCondition(
    double deltaTopReversed,
    double deltaBottomReversed,
    double viewPortDimension,
  ) => false;

  @override
  bool isEventVisible(Event event) => event.isVisibleInGui;

  @override
  bool get isRequestingHistory => false;

  @override
  bool get canRequestHistory => false;

  @override
  void clearHighlightedEvent() {}

  @override
  void handleScrollStartNotification() {}

  @override
  void handleScrollEndNotification() {}

  @override
  void handleScrollUpdateNotification() {}

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) => '_Chat';
}

/// The chat of [room], the seen style stored as [seenStyle]. Returns once
/// the stored choices are read and the list is built again with them.
Future<void> _pumpChat(
  WidgetTester tester,
  _CountingRoom room, {
  required String seenStyle,
}) async {
  SharedPreferences.setMockInitialValues({SettingKeys.seenStyle: seenStyle});
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        home: Scaffold(body: ChatEventList(controller: _Chat(room))),
      ),
    ),
  );
  for (var i = 0; i < 4; i++) {
    await tester.pump(const Duration(milliseconds: 250));
  }
}

void main() {
  setUp(() => getIt.registerSingleton(ResponsiveUtils()));
  tearDown(() async => getIt.reset());

  testWidgets('with the ticks, the chat does not work out who read up to '
      'where: no receipt is read', (tester) async {
    final room = _CountingRoom(_Client());

    await _pumpChat(tester, room, seenStyle: 'ticks');

    expect(room.receiptReads, 0);
  });

  // The other side: the count above does see a chat that works it out.
  for (final style in ['avatars', 'names']) {
    testWidgets('with the $style, the chat reads the receipts to place the '
        'readers', (tester) async {
      final room = _CountingRoom(_Client());

      await _pumpChat(tester, room, seenStyle: style);

      expect(room.receiptReads, greaterThan(0));
    });
  }
}
