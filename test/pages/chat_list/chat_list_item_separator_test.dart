import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart'
    show LinagoraDividerStyle;
import 'package:matrix/matrix.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:twake_chat/domain/model/room/room_preview_result.dart';
import 'package:twake_chat/pages/chat/seen_by_row.dart';
import 'package:twake_chat/pages/chat_list/chat_list_item.dart';
import 'package:twake_chat/pages/chat_list/chat_list_row_divider.dart';
import 'package:twake_chat/presentation/model/chat_list/room_list_row.dart';
import 'package:twake_chat/presentation/model/chat_list/space_row_data.dart';
import 'package:twake_chat/utils/responsive/responsive_utils.dart';
import 'package:twake_chat/widgets/avatar/avatar_with_kind_badge.dart';

import 'chat_list_item_test.dart' show buildRoom, wrap;
import 'chat_list_item_test.mocks.dart';

/// The need (Clément): the line between two rows of the chat list starts
/// after the avatar, at the left edge of the title, and stops before the
/// read-status icon at the end of the row. It keeps its colour and thickness.
final _divider = LinagoraDividerStyle.material();

/// The lines of the design-system colour drawn by the rows' dividers.
final _lines = find.descendant(
  of: find.byType(ChatListRowDivider),
  matching: find.byWidgetPredicate(
    (widget) => widget is ColoredBox && widget.color == _divider.color,
  ),
);

/// The separators on screen, top to bottom.
List<Rect> _separators(WidgetTester tester) => [
  for (var i = 0; i < _lines.evaluate().length; i++)
    tester.getRect(_lines.at(i)),
];

/// A row without preview animates its placeholder for ever: no pumpAndSettle.
Future<void> _pumpRows(WidgetTester tester, List<Widget> rows) async {
  await tester.pumpWidget(wrap(Column(children: rows)));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
}

Event _ownMessage(Room room) => Event(
  eventId: r'$own',
  senderId: '@me:server.tld',
  type: EventTypes.Message,
  content: {'msgtype': 'm.text', 'body': 'hello'},
  originServerTs: DateTime(2020, 1, 1),
  status: EventStatus.synced,
  room: room,
);

MockRoom _chat(String name, {String id = '!room:server.tld'}) {
  final room = buildRoom(name: name, id: id);
  when(room.receiptState).thenReturn(LatestReceiptState.empty());
  when(room.typingUsers).thenReturn([]);
  return room;
}

/// A row whose last message is mine: it shows the read-status icon.
ChatListItem _readRow(MockRoom room) =>
    ChatListItem(room, previewResult: RoomPreviewFound(_ownMessage(room)));

double _titleLeft(WidgetTester tester, String title) =>
    tester.getRect(find.text(title)).left;

void main() {
  setUpAll(() {
    final getIt = GetIt.instance;
    if (!getIt.isRegistered<ResponsiveUtils>()) {
      getIt.registerSingleton(ResponsiveUtils());
    }
  });

  // The theme of the harness reads the preferences.
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('separator of a chat row', () {
    _startsAtTheTitle();
    _stopsBeforeTheReadStatus();
    _looksLikeTheDesignSystemDivider();
    _keepsTheSpaceBadgeAbove();
  });
}

void _startsAtTheTitle() {
  testWidgets('starts at the left edge of the title, after the avatar', (
    tester,
  ) async {
    await _pumpRows(tester, [ChatListItem(_chat('Project Apollo'))]);

    final line = _separators(tester).single;
    expect(line.left, _titleLeft(tester, 'Project Apollo'));
  });

  testWidgets('starts at the left edge of the title of a room indented in '
      'a space', (tester) async {
    await _pumpRows(tester, [ChatListItem(_chat('General'), depth: 1)]);

    final line = _separators(tester).single;
    expect(line.left, _titleLeft(tester, 'General'));
  });

  testWidgets('starts at the left edge of the title in select mode', (
    tester,
  ) async {
    await _pumpRows(tester, [
      ChatListItem(
        _chat('Project Apollo'),
        isEnableSelectMode: true,
        checkBoxWidget: Checkbox(value: false, onChanged: (_) {}),
      ),
    ]);

    final line = _separators(tester).single;
    expect(line.left, _titleLeft(tester, 'Project Apollo'));
  });
}

void _stopsBeforeTheReadStatus() {
  testWidgets('stops before the read-status icon', (tester) async {
    await _pumpRows(tester, [_readRow(_chat('Project Apollo'))]);

    final line = _separators(tester).single;
    final readStatus = tester.getRect(find.byType(SeenByRow));
    expect(line.right, lessThanOrEqualTo(readStatus.left));
  });

  testWidgets('stops at the same place on a row without read-status icon', (
    tester,
  ) async {
    await _pumpRows(tester, [
      _readRow(_chat('Project Apollo')),
      ChatListItem(_chat('Project Gemini', id: '!other:server.tld')),
    ]);

    final lines = _separators(tester);
    final readStatus = tester.getRect(find.byType(SeenByRow));
    expect(lines, hasLength(2));
    expect(lines.last.right, lines.first.right);
    expect(lines.last.right, lessThanOrEqualTo(readStatus.left));
  });
}

void _looksLikeTheDesignSystemDivider() {
  testWidgets('keeps the colour and the thickness of the design system '
      'divider', (tester) async {
    await _pumpRows(tester, [ChatListItem(_chat('Project Apollo'))]);

    // Only lines of the LinagoraDividerStyle colour are found.
    final line = _separators(tester).single;
    expect(line.height, _divider.thickness);
  });

  testWidgets('draws exactly one line per row, under the row', (tester) async {
    await _pumpRows(tester, [
      ChatListItem(_chat('Project Apollo')),
      ChatListItem(_chat('Project Gemini', id: '!other:server.tld')),
    ]);

    final lines = _separators(tester);
    final rows = find.byType(ChatListItem);
    expect(lines, hasLength(2));
    expect(lines.first.bottom, tester.getRect(rows.first).bottom);
    expect(lines.last.bottom, tester.getRect(rows.last).bottom);
  });
}

// #3711: the kind badge of a space avatar sat on the line under the row.
void _keepsTheSpaceBadgeAbove() {
  testWidgets('a space row keeps its kind badge above the line', (
    tester,
  ) async {
    final space = _chat('Team');
    when(space.isDirectChat).thenReturn(false);
    when(space.isSpace).thenReturn(true);
    final row = SpaceRowData(
      fold: SpaceFold.none,
      unreadCount: 0,
      mentionCount: 0,
      onToggleFold: () {},
    );

    await _pumpRows(tester, [ChatListItem(space, space: row)]);

    final line = _separators(tester).single;
    final badge = tester.getRect(
      find.descendant(
        of: find.byType(AvatarWithKindBadge),
        matching: find.byType(Icon),
      ),
    );
    expect(badge.bottom, lessThanOrEqualTo(line.top));
  });
}
