import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
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
import 'package:twake_chat/utils/responsive/responsive_utils.dart';

import 'chat_list_item_test.dart' show buildRoom, wrap;
import 'chat_list_item_test.mocks.dart';

/// The need (Clément): the line between two rows of the chat list starts
/// after the avatar, at the left edge of the title, and stops before the
/// read-status icon at the end of the row. It keeps its colour and thickness.
///
/// The specs read the line in the painted pixels, as the user sees it, so the
/// fix is free to draw it any way.
const _shot = ValueKey('separator-shot');

/// A horizontal run shorter than this is not a separator (glyph, badge).
const _minLineLength = 24;

Widget _rows(List<Widget> rows) => wrap(
  RepaintBoundary(
    key: _shot,
    child: Column(children: rows),
  ),
);

bool _near(int a, int b) => (a - b).abs() <= 2;

/// The separators painted on screen: every horizontal line that has the
/// colour of [LinagoraDividerStyle] over the background of the row.
Future<List<Rect>> _separators(WidgetTester tester) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(_shot),
  );
  final origin = tester.getTopLeft(find.byKey(_shot));
  final (width, height, bytes) = (await tester.runAsync(() async {
    final image = await boundary.toImage();
    final data = await image.toByteData();
    final result = (image.width, image.height, data!);
    image.dispose();
    return result;
  }))!;

  Color pixel(int x, int y) {
    final i = (y * width + x) * 4;
    return Color.fromARGB(
      255,
      bytes.getUint8(i),
      bytes.getUint8(i + 1),
      bytes.getUint8(i + 2),
    );
  }

  int channel(double value) => (value * 255).round();

  // An empty spot of the row: inside its body, above the avatar and the text.
  final row = tester.getRect(find.byType(ChatListItem).first);
  final background = pixel(
    (row.left - origin.dx).round() + 10,
    (row.top - origin.dy).round() + 2,
  );
  final line = Color.alphaBlend(
    LinagoraDividerStyle.material().color,
    background,
  );
  bool isLine(int x, int y) {
    final c = pixel(x, y);
    return _near(channel(c.r), channel(line.r)) &&
        _near(channel(c.g), channel(line.g)) &&
        _near(channel(c.b), channel(line.b));
  }

  final lines = <Rect>[];
  for (var y = 0; y < height; y++) {
    var x = 0;
    while (x < width) {
      if (!isLine(x, y)) {
        x++;
        continue;
      }
      final start = x;
      while (x < width && isLine(x, y)) {
        x++;
      }
      if (x - start < _minLineLength) continue;
      final run = Rect.fromLTRB(
        start + origin.dx,
        y + origin.dy,
        x + origin.dx,
        y + 1 + origin.dy,
      );
      final above = lines.indexWhere(
        (l) =>
            l.left == run.left && l.right == run.right && l.bottom == run.top,
      );
      if (above == -1) {
        lines.add(run);
      } else {
        lines[above] = lines[above].expandToInclude(run);
      }
    }
  }
  return lines;
}

/// A row without preview animates its placeholder for ever: no pumpAndSettle.
Future<void> _settle(WidgetTester tester) async {
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
    testWidgets('starts at the left edge of the title, after the avatar', (
      tester,
    ) async {
      await tester.pumpWidget(_rows([ChatListItem(_chat('Project Apollo'))]));
      await _settle(tester);

      final line = (await _separators(tester)).single;
      expect(line.left, tester.getRect(find.text('Project Apollo')).left);
    });

    testWidgets('starts at the left edge of the title of a room indented in '
        'a space', (tester) async {
      await tester.pumpWidget(
        _rows([ChatListItem(_chat('General'), depth: 1)]),
      );
      await _settle(tester);

      final line = (await _separators(tester)).single;
      expect(line.left, tester.getRect(find.text('General')).left);
    });

    testWidgets('starts at the left edge of the title in select mode', (
      tester,
    ) async {
      await tester.pumpWidget(
        _rows([
          ChatListItem(
            _chat('Project Apollo'),
            isEnableSelectMode: true,
            checkBoxWidget: Checkbox(value: false, onChanged: (_) {}),
          ),
        ]),
      );
      await _settle(tester);

      final line = (await _separators(tester)).single;
      expect(line.left, tester.getRect(find.text('Project Apollo')).left);
    });

    testWidgets('stops before the read-status icon', (tester) async {
      final room = _chat('Project Apollo');

      await tester.pumpWidget(
        _rows([
          ChatListItem(
            room,
            previewResult: RoomPreviewFound(_ownMessage(room)),
          ),
        ]),
      );
      await _settle(tester);

      final line = (await _separators(tester)).single;
      final readStatus = tester.getRect(find.byType(SeenByRow));
      expect(line.right, lessThanOrEqualTo(readStatus.left));
    });

    testWidgets('stops at the same place on a row without read-status icon', (
      tester,
    ) async {
      final withIcon = _chat('Project Apollo');
      final withoutIcon = _chat('Project Gemini', id: '!other:server.tld');

      await tester.pumpWidget(
        _rows([
          ChatListItem(
            withIcon,
            previewResult: RoomPreviewFound(_ownMessage(withIcon)),
          ),
          ChatListItem(withoutIcon),
        ]),
      );
      await _settle(tester);

      final lines = await _separators(tester);
      final readStatus = tester.getRect(find.byType(SeenByRow));
      expect(lines, hasLength(2));
      expect(lines.last.right, lines.first.right);
      expect(lines.last.right, lessThanOrEqualTo(readStatus.left));
    });

    testWidgets('keeps the colour and the thickness of the design system '
        'divider', (tester) async {
      await tester.pumpWidget(_rows([ChatListItem(_chat('Project Apollo'))]));
      await _settle(tester);

      // Only lines of the LinagoraDividerStyle colour are found.
      final line = (await _separators(tester)).single;
      expect(line.height, LinagoraDividerStyle.material().thickness);
    });

    testWidgets('draws exactly one line per row, under the row', (
      tester,
    ) async {
      await tester.pumpWidget(
        _rows([
          ChatListItem(_chat('Project Apollo')),
          ChatListItem(_chat('Project Gemini', id: '!other:server.tld')),
        ]),
      );
      await _settle(tester);

      final lines = await _separators(tester);
      final rows = find.byType(ChatListItem);
      expect(lines, hasLength(2));
      expect(lines.first.bottom, tester.getRect(rows.first).bottom);
      expect(lines.last.bottom, tester.getRect(rows.last).bottom);
    });
  });
}
