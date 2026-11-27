import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:matrix/matrix.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:twake_chat/config/setting_keys.dart';
import 'package:twake_chat/domain/model/room/room_preview_result.dart';
import 'package:twake_chat/pages/chat_list/chat_list_item.dart';
import 'package:twake_chat/utils/responsive/responsive_utils.dart';

import 'chat_list_item_test.dart' show buildRoom, wrap;
import 'chat_list_item_test.mocks.dart';

/// Shows [item] with the density stored as [density] (nothing stored when
/// null), and lets the preferences and the sender load.
Future<void> _show(
  WidgetTester tester,
  String? density,
  ChatListItem item,
) async {
  SharedPreferences.setMockInitialValues({
    if (density != null) SettingKeys.chatListDensity: density,
  });
  await tester.pumpWidget(ProviderScope(key: UniqueKey(), child: wrap(item)));
  for (var i = 0; i < 4; i++) {
    await tester.pump(const Duration(milliseconds: 250));
  }
}

/// The height of one room of the chat list, the density stored as [density]
/// (nothing stored when null).
Future<double> _rowHeight(WidgetTester tester, String? density) async {
  await _show(tester, density, ChatListItem(buildRoom(name: 'Project Apollo')));
  return tester.getSize(find.byType(ChatListItem)).height;
}

/// A phone, 390 px wide, at the default text scale.
void _phone(WidgetTester tester) {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

const _roomName = 'Project Apollo';
const _senderName = 'Bob';
const _message = 'see you tomorrow';

/// A group room whose last message is a text from another member: the row
/// with three lines (room name, sender name, message).
(MockRoom, RoomPreviewResult) _groupWithMessageFromOther({
  bool direct = false,
}) {
  final room = buildRoom(name: _roomName);
  when(room.isDirectChat).thenReturn(direct);
  when(room.receiptState).thenReturn(LatestReceiptState.empty());
  when(room.typingUsers).thenReturn([]);
  final bob = User('@bob:server.tld', displayName: _senderName, room: room);
  when(
    room.requestUser(
      any,
      ignoreErrors: anyNamed('ignoreErrors'),
      requestProfile: anyNamed('requestProfile'),
    ),
  ).thenAnswer((_) async => bob);
  when(room.unsafeGetUserFromMemoryOrFallback(any)).thenReturn(bob);
  final event = Event(
    eventId: r'$other',
    senderId: '@bob:server.tld',
    type: EventTypes.Message,
    content: {'msgtype': 'm.text', 'body': _message},
    originServerTs: DateTime(2020, 1, 1),
    status: EventStatus.synced,
    room: room,
  );
  return (room, RoomPreviewFound(event));
}

/// [text] is drawn inside the row, not cut by its bottom.
void _expectInsideRow(WidgetTester tester, String text) {
  final row = tester.getRect(find.byType(ChatListItem));
  final line = tester.getRect(find.text(text));
  expect(line.top, greaterThanOrEqualTo(row.top), reason: '"$text" top');
  expect(line.bottom, lessThanOrEqualTo(row.bottom), reason: '"$text" bottom');
}

/// The row shows each of [lines] without an overflow.
void _expectFits(WidgetTester tester, List<String> lines) {
  expect(tester.takeException(), isNull);
  for (final line in lines) {
    _expectInsideRow(tester, line);
  }
}

void main() {
  setUpAll(() {
    if (!GetIt.instance.isRegistered<ResponsiveUtils>()) {
      GetIt.instance.registerSingleton(ResponsiveUtils());
    }
  });

  testWidgets('a compact chat list shows shorter rooms than a comfortable '
      'one', (tester) async {
    final comfortable = await _rowHeight(tester, 'comfortable');
    final compact = await _rowHeight(tester, 'compact');

    expect(compact, lessThan(comfortable));
  });

  testWidgets('nothing chosen: the rooms are taller than compact ones', (
    tester,
  ) async {
    final unset = await _rowHeight(tester, null);
    final compact = await _rowHeight(tester, 'compact');

    expect(compact, lessThan(unset));
  });

  _compactRowsTests();
}

void _compactRowsTests() {
  group('compact rows fit their lines on a phone', () {
    testWidgets('a group room with a message from another member shows its '
        'name, the sender and the message without overflow', (tester) async {
      _phone(tester);
      final (room, preview) = _groupWithMessageFromOther();

      await _show(
        tester,
        'compact',
        ChatListItem(room, previewResult: preview),
      );

      _expectFits(tester, [_roomName, _senderName, _message]);
    });

    testWidgets('a group room nested under a space shows its three lines '
        'without overflow', (tester) async {
      _phone(tester);
      final (room, preview) = _groupWithMessageFromOther();

      await _show(
        tester,
        'compact',
        ChatListItem(room, previewResult: preview, depth: 1),
      );

      _expectFits(tester, [_roomName, _senderName, _message]);
    });

    testWidgets('a compact group row stays shorter than a comfortable one', (
      tester,
    ) async {
      _phone(tester);
      final (room, preview) = _groupWithMessageFromOther();

      await _show(
        tester,
        'comfortable',
        ChatListItem(room, previewResult: preview),
      );
      final comfortable = tester.getSize(find.byType(ChatListItem)).height;
      await _show(
        tester,
        'compact',
        ChatListItem(room, previewResult: preview),
      );
      final compact = tester.getSize(find.byType(ChatListItem)).height;
      // Only the height here: the overflow is pinned by the tests above.
      tester.takeException();

      expect(compact, lessThan(comfortable));
    });

    testWidgets('a direct chat shows its name and the message without '
        'overflow', (tester) async {
      _phone(tester);
      final (room, preview) = _groupWithMessageFromOther(direct: true);

      await _show(
        tester,
        'compact',
        ChatListItem(room, previewResult: preview),
      );

      _expectFits(tester, [_roomName, _message]);
    });
  });
}
