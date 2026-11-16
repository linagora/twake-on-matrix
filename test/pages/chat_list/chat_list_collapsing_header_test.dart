import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart' as provider;
import 'package:visibility_detector/visibility_detector.dart';
import 'package:twake_chat/di/global/get_it_initializer.dart';
import 'package:twake_chat/domain/spaces/room_list_entry.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:twake_chat/pages/chat_list/chat_list.dart';
import 'package:twake_chat/pages/chat_list/chat_list_header.dart';
import 'package:twake_chat/pages/chat_list/chat_list_view.dart';
import 'package:twake_chat/pages/chat_list/room_list_filter/room_list_filter_bar.dart';
import 'package:twake_chat/pages/chat_list/room_list_filter/room_list_filter_style.dart';
import 'package:twake_chat/presentation/enum/chat_list/chat_list_enum.dart';
import 'package:twake_chat/presentation/model/chat_list/chat_selection_actions.dart';
import 'package:twake_chat/providers/room_list/folded_spaces_controller.dart';
import 'package:twake_chat/providers/room_list/folders_controller.dart';
import 'package:twake_chat/providers/room_list/room_list_providers.dart';
import 'package:twake_chat/utils/responsive/responsive_utils.dart';
import 'package:twake_chat/widgets/matrix.dart';
import 'package:linagora_design_flutter/style/linagora_text_theme.dart';

import '../../fake_client.dart';
import '../../providers/fake_active_account.dart';

// Contract for the implementer: the whole top block of the room list
// (TwakeHeader + search + RoomListFilterBar) stays one `ChatListHeader`
// widget, whether it sits in the Scaffold appBar (wide layouts) or in a
// SliverAppBar of the CustomScrollView of ChatListBodyView (one column).
final _header = find.byType(ChatListHeader);

const _mobileSize = Size(400, 800);
const _wideSize = Size(1400, 900);

/// Status bar of an iPhone with a notch, in logical pixels.
const _statusBar = 47.0;

/// What the Scaffold gave the old appBar: preferredSize + the status bar.
const _headerBlockHeight = 120 + RoomListFilterStyle.height + _statusBar;

void main() {
  setUpAll(() {
    VisibilityDetectorController.instance.updateInterval = Duration.zero;
    if (!getIt.isRegistered<ResponsiveUtils>()) {
      getIt.registerSingleton(ResponsiveUtils());
    }
  });

  group('[ChatList] collapsing header on a one column layout', () {
    testWidgets('GIVEN the top of the list\n'
        'THEN the header is shown above the first room', (tester) async {
      final h = await _Harness.pump(tester, size: _mobileSize);
      expect(_headerVisible(tester), isTrue);
      expect(h.scroll.offset, 0);
      expect(find.byType(ChatListHeader), findsOneWidget);
    });

    testWidgets('GIVEN the list is scrolled down by more than the header\n'
        'THEN the header is hidden', (tester) async {
      final h = await _Harness.pump(tester, size: _mobileSize);

      await _scrollDown(tester, 400);

      expect(h.scroll.offset, greaterThan(0));
      expect(_headerVisible(tester), isFalse);
    });

    testWidgets('GIVEN the header is hidden\n'
        'WHEN the user scrolls back up a little\n'
        'THEN the header comes back and ends fully visible', (tester) async {
      await _Harness.pump(tester, size: _mobileSize);
      await _scrollDown(tester, 400);
      expect(_headerVisible(tester), isFalse);

      await tester.drag(find.byType(CustomScrollView), const Offset(0, 60));
      await tester.pumpAndSettle();

      expect(_headerVisible(tester), isTrue);
      final top = tester.getTopLeft(_header).dy;
      expect(top, greaterThanOrEqualTo(0));
      expect(tester.getRect(_header).bottom, greaterThan(100));
    });

    testWidgets('GIVEN the user scrolls back to the very top\n'
        'THEN the header is shown at its full height', (tester) async {
      final h = await _Harness.pump(tester, size: _mobileSize);
      final fullHeight = tester.getSize(_header).height;
      await _scrollDown(tester, 400);

      h.scroll.jumpTo(0);
      await tester.pumpAndSettle();

      expect(tester.getTopLeft(_header).dy, 0);
      expect(tester.getSize(_header).height, fullHeight);
    });

    testWidgets('GIVEN select mode\n'
        'THEN scrolling down never hides the header', (tester) async {
      final h = await _Harness.pump(tester, size: _mobileSize);
      h.controller.selectModeNotifier.value = SelectMode.select;
      await tester.pump();

      await _scrollDown(tester, 400);

      expect(h.scroll.offset, greaterThan(0));
      expect(_headerVisible(tester), isTrue);
    });

    testWidgets('GIVEN the header is hidden\n'
        'WHEN select mode starts\n'
        'THEN the header is shown again', (tester) async {
      final h = await _Harness.pump(tester, size: _mobileSize);
      await _scrollDown(tester, 400);
      expect(_headerVisible(tester), isFalse);

      h.controller.selectModeNotifier.value = SelectMode.select;
      await tester.pumpAndSettle();

      expect(_headerVisible(tester), isTrue);
    });

    testWidgets('GIVEN the controller scrolls the list itself\n'
        'THEN the scroll listener of the controller still fires', (
      tester,
    ) async {
      final h = await _Harness.pump(tester, size: _mobileSize);
      var calls = 0;
      var lastWasTop = true;
      h.scroll.addListener(() {
        calls++;
        lastWasTop = h.scroll.position.pixels <= 0;
      });

      await _scrollDown(tester, 400);
      expect(lastWasTop, isFalse);
      h.scroll.jumpTo(0);
      await tester.pumpAndSettle();

      expect(calls, greaterThan(0));
      expect(lastWasTop, isTrue);
    });

    testWidgets('GIVEN no room yet\n'
        'THEN the header is shown at the top, without scrolling', (
      tester,
    ) async {
      await _Harness.pump(tester, size: _mobileSize, roomCount: 0);

      expect(_headerVisible(tester), isTrue);
      expect(find.byType(CustomScrollView), findsNothing);
      expect(tester.getTopLeft(_header).dy, 0);
    });
  });

  group('[ChatList] header on a multi column layout', () {
    testWidgets('GIVEN a wide screen\n'
        'THEN the header stays in the app bar and never hides', (tester) async {
      final h = await _Harness.pump(tester, size: _wideSize);
      expect(_headerVisible(tester), isTrue);
      expect(
        find.descendant(of: find.byType(CustomScrollView), matching: _header),
        findsNothing,
        reason: 'wide layouts keep the header outside the scrolling list',
      );

      await _scrollDown(tester, 400);

      expect(h.scroll.offset, greaterThan(0));
      expect(_headerVisible(tester), isTrue);
    });
  });

  group('[ChatList] header block with a status bar inset', () {
    final branches = <String, _Branch>{
      'the list': const _Branch(),
      'the empty list': const _Branch(roomCount: 0),
      'the skeleton': const _Branch(roomCount: 0, skeleton: true),
    };

    for (final entry in branches.entries) {
      final name = entry.key;
      final branch = entry.value;

      testWidgets('GIVEN $name on a phone with a status bar\n'
          'THEN nothing overflows', (tester) async {
        await _Harness.pump(
          tester,
          size: _mobileSize,
          topInset: _statusBar,
          branch: branch,
        );

        expect(tester.takeException(), isNull);
      });

      testWidgets('GIVEN $name on a phone with a status bar\n'
          'THEN the chips sit inside the header, inside its reserved box', (
        tester,
      ) async {
        await _Harness.pump(
          tester,
          size: _mobileSize,
          topInset: _statusBar,
          branch: branch,
        );
        tester.takeException();

        final header = tester.getRect(_header);
        final chips = tester.getRect(find.byType(RoomListFilterBar));
        final reserved = tester.getRect(_reservedBox);
        expect(chips.top, greaterThanOrEqualTo(header.top - 0.01));
        expect(chips.bottom, lessThanOrEqualTo(header.bottom + 0.01));
        expect(header.bottom, lessThanOrEqualTo(reserved.bottom + 0.01));
      });

      testWidgets('GIVEN $name on a phone with a status bar\n'
          'THEN the block is as high as the old appBar: preferred height '
          'plus the status bar', (tester) async {
        await _Harness.pump(
          tester,
          size: _mobileSize,
          topInset: _statusBar,
          branch: branch,
        );
        tester.takeException();

        expect(tester.getSize(_reservedBox).height, _headerBlockHeight);
        expect(tester.getSize(_header).height, _headerBlockHeight);
      });
    }

    testWidgets('GIVEN a wide screen with the same status bar\n'
        'THEN its appBar block has the height the phone block must have', (
      tester,
    ) async {
      await _Harness.pump(tester, size: _wideSize, topInset: _statusBar);

      expect(tester.getSize(_header).height, _headerBlockHeight);
    });

    testWidgets('GIVEN the chips of the filter bar on screen\n'
        'WHEN select mode starts (the header becomes pinned)\n'
        'THEN the filter bar keeps its state, it is not mounted again', (
      tester,
    ) async {
      final h = await _Harness.pump(
        tester,
        size: _mobileSize,
        topInset: _statusBar,
      );
      final before = tester.state(find.byType(RoomListFilterBar));

      h.controller.selectModeNotifier.value = SelectMode.select;
      await tester.pumpAndSettle();

      expect(tester.state(find.byType(RoomListFilterBar)), same(before));
    });

    testWidgets('GIVEN the list scrolled down with a status bar\n'
        'THEN the header is entirely above the screen, nothing of it shows', (
      tester,
    ) async {
      await _Harness.pump(tester, size: _mobileSize, topInset: _statusBar);
      tester.takeException();

      await _scrollDown(tester, 600);

      expect(_headerVisible(tester), isFalse);
      // Either not built at all, or built and entirely above the screen.
      if (_header.evaluate().isNotEmpty) {
        expect(tester.getRect(_header).bottom, lessThanOrEqualTo(0));
      }
    });
  });
  group('[ChatList] header background colour on a one column layout', () {
    testWidgets('GIVEN the header comes back after a scroll\n'
        'THEN its background is the colour it has at the top of the list', (
      tester,
    ) async {
      final h = await _Harness.pump(
        tester,
        size: _mobileSize,
        topInset: _statusBar,
      );
      final atTop = await _backgroundColor(tester);

      await _scrollDown(tester, 400);
      await tester.drag(find.byType(CustomScrollView), const Offset(0, 80));
      await tester.pumpAndSettle();
      expect(_headerVisible(tester), isTrue);
      final comeBack = await _backgroundColor(tester);
      expect(h.scroll.offset, greaterThan(0));

      expect(comeBack, atTop, reason: 'top $atTop, after scroll $comeBack');
    });

    testWidgets('GIVEN select mode, pinned, after a scroll\n'
        'THEN its background is the colour it has in select mode at the top', (
      tester,
    ) async {
      final h = await _Harness.pump(
        tester,
        size: _mobileSize,
        topInset: _statusBar,
      );
      h.controller.selectModeNotifier.value = SelectMode.select;
      await tester.pumpAndSettle();
      final atTop = await _backgroundColor(tester);

      await _scrollDown(tester, 400);
      await tester.drag(find.byType(CustomScrollView), const Offset(0, 80));
      await tester.pumpAndSettle();
      final scrolled = await _backgroundColor(tester);
      expect(h.scroll.offset, greaterThan(0));

      expect(scrolled, atTop, reason: 'top $atTop, after scroll $scrolled');
    });
  });
  group('[ChatList] status bar band on a one column layout', () {
    testWidgets('GIVEN the header is hidden by the scroll\n'
        'THEN the status bar band has the colour it has at the top', (
      tester,
    ) async {
      await _Harness.pump(tester, size: _mobileSize, topInset: _statusBar);
      final atTop = await _bandColor(tester);

      await _scrollDown(tester, 400);
      expect(_headerVisible(tester), isFalse);

      expect(await _bandColor(tester), atTop);
    });

    testWidgets('GIVEN select mode, pinned, after a scroll\n'
        'THEN the band has the colour it has in select mode at the top', (
      tester,
    ) async {
      final h = await _Harness.pump(
        tester,
        size: _mobileSize,
        topInset: _statusBar,
      );
      h.controller.selectModeNotifier.value = SelectMode.select;
      await tester.pumpAndSettle();
      final atTop = await _bandColor(tester);

      await _scrollDown(tester, 400);

      expect(await _bandColor(tester), atTop);
    });

    testWidgets('GIVEN the header comes back after a scroll\n'
        'THEN the band has the colour it has at the top', (tester) async {
      await _Harness.pump(tester, size: _mobileSize, topInset: _statusBar);
      final atTop = await _bandColor(tester);

      await _scrollDown(tester, 400);
      await tester.drag(find.byType(CustomScrollView), const Offset(0, 80));
      await tester.pumpAndSettle();
      expect(_headerVisible(tester), isTrue);

      expect(await _bandColor(tester), atTop);
    });

    testWidgets('GIVEN the list scrolls further down\n'
        'THEN no row is painted in the band: its pixel never changes', (
      tester,
    ) async {
      await _Harness.pump(tester, size: _mobileSize, topInset: _statusBar);
      final atTop = await _bandColor(tester);

      await _scrollDown(tester, 400);
      final first = await _bandColor(tester);
      await _scrollDown(tester, 800);
      final second = await _bandColor(tester);

      expect(first, atTop);
      expect(second, atTop);
    });

    testWidgets('GIVEN a wide screen scrolled down\n'
        'THEN the band stays opaque, the app bar still covers it', (
      tester,
    ) async {
      await _Harness.pump(tester, size: _wideSize, topInset: _statusBar);

      await _scrollDown(tester, 400);

      expect((await _bandColor(tester)).a, 1.0);
    });

    for (final entry in {
      'the empty list': const _Branch(roomCount: 0),
      'the skeleton': const _Branch(roomCount: 0, skeleton: true),
    }.entries) {
      testWidgets('GIVEN ${entry.key} with a status bar\n'
          'THEN the band is opaque and the colour of the header', (
        tester,
      ) async {
        await _Harness.pump(
          tester,
          size: _mobileSize,
          topInset: _statusBar,
          branch: entry.value,
        );

        final band = await _bandColor(tester);
        expect(band.a, 1.0);
        expect(band, await _backgroundColor(tester));
      });
    }
  });
}

final _screenKey = GlobalKey();

/// Colour really painted at x=100, y=20: inside the status bar band, no text.
Future<Color> _bandColor(WidgetTester tester) => _pixel(tester, 100, 20);

Future<Color> _backgroundColor(WidgetTester tester) =>
    _pixel(tester, 2, (_statusBar + 28).toInt());

/// Colour really painted at (x, y), read from the screen boundary.
Future<Color> _pixel(WidgetTester tester, int x, int y) async {
  final boundary =
      _screenKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  return (await tester.runAsync(() async {
    final image = await boundary.toImage();
    final data = (await image.toByteData())!;
    final i = (y * image.width + x) * 4;
    return Color.fromARGB(
      data.getUint8(i + 3),
      data.getUint8(i),
      data.getUint8(i + 1),
      data.getUint8(i + 2),
    );
  }))!;
}

/// The box the layout reserves for the header block: the app bar of the
/// SliverAppBar on the list, the SizedBox of the empty and skeleton views.
final _reservedBox = find
    .ancestor(
      of: _header,
      matching: find.byWidgetPredicate((w) => w is AppBar || w is SizedBox),
    )
    .first;

class _Branch {
  const _Branch({this.roomCount = 30, this.skeleton = false});

  final int roomCount;

  /// No first sync yet: the skeleton is shown.
  final bool skeleton;
}

/// Built and on the screen.
bool _headerVisible(WidgetTester tester) {
  final finder = _header;
  if (finder.evaluate().isEmpty) return false;
  final screen = tester.view.physicalSize / tester.view.devicePixelRatio;
  final rect = tester.getRect(finder);
  return rect.bottom > 0 &&
      rect.height > 0 &&
      rect.overlaps(Offset.zero & screen) &&
      finder.hitTestable().evaluate().isNotEmpty;
}

Future<void> _scrollDown(WidgetTester tester, double distance) async {
  await tester.drag(find.byType(CustomScrollView), Offset(0, -distance));
  await tester.pumpAndSettle();
}

class _Harness {
  _Harness(this.controller);

  final _Controller controller;
  ScrollController get scroll => controller.scrollController;

  static Future<_Harness> pump(
    WidgetTester tester, {
    required Size size,
    int roomCount = 30,
    double topInset = 0,
    _Branch? branch,
  }) async {
    if (branch != null) roomCount = branch.roomCount;
    final skeleton = branch?.skeleton ?? false;
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    tester.view.padding = FakeViewPadding(top: topInset);
    tester.view.viewPadding = FakeViewPadding(top: topInset);
    addTearDown(tester.view.reset);

    final client = (await tester.runAsync(
      () => _syncedClient(synced: !skeleton),
    ))!;
    for (var i = 0; i < roomCount; i++) {
      client.rooms.add(Room(id: '!room$i:fakeServer', client: client));
    }
    final matrix = _MatrixState(client)..waitForFirstSync = skeleton;
    final controller = _Controller(matrix, client);
    final entries = [
      for (var i = 0; i < roomCount; i++)
        RoomListEntry(id: '!room$i:fakeServer', name: 'Room $i'),
    ];

    await tester.pumpWidget(
      provider.Provider<MatrixState>.value(
        value: matrix,
        child: UncontrolledProviderScope(
          container: ProviderContainer.test(
            overrides: [
              ...activeAccountOverrides(client),
              roomListContentProvider.overrideWith(
                (ref, _) => RoomListContent(
                  visible: entries,
                  foldedSpaceIds: const {},
                  joinableBySpace: const {},
                ),
              ),
              roomListFoldersProvider.overrideWithValue(const []),
              foldedSpacesControllerProvider.overrideWith(_NoFold.new),
            ],
          ),
          child: RepaintBoundary(
            key: _screenKey,
            child: MaterialApp(
              theme: ThemeData(
                extensions: [LinagoraTextThemeExtension.material()],
              ),
              locale: const Locale('en'),
              localizationsDelegates: L10n.localizationsDelegates,
              supportedLocales: L10n.supportedLocales,
              home: ChatListView(
                controller: controller,
                onTapBottomNavigation: (_) {},
              ),
            ),
          ),
        ),
      ),
    );
    if (skeleton) {
      // The skeleton shimmers for ever: pumpAndSettle would never return.
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));
    } else {
      await tester.pumpAndSettle();
    }
    // Precondition of every case: without it a "hidden" check would pass on
    // a header that does not exist at all.
    expect(
      _headerVisible(tester),
      isTrue,
      reason: 'the header (ChatListHeader) is on screen at the top',
    );
    return _Harness(controller);
  }
}

class _NoFold extends FoldedSpacesController {
  @override
  Future<Set<String>> build() async => <String>{};
}

class _MatrixState extends Mock implements MatrixState {
  _MatrixState(this.client);

  @override
  final Client client;
  @override
  final voiceMessageEvent = ValueNotifier<Event?>(null);
  @override
  final showToMBootstrap = ValueNotifier<bool>(false);
  @override
  bool waitForFirstSync = false;
  @override
  final initSettingsCompleter = Completer<void>()..complete();
  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) =>
      '_MatrixState';
}

class _Controller extends Mock implements ChatListController {
  _Controller(this._matrix, this._client);

  final _MatrixState _matrix;
  final Client _client;

  @override
  final selectModeNotifier = ValueNotifier(SelectMode.normal);
  @override
  final conversationSelectionNotifier =
      ValueNotifier<List<ConversationSelectionPresentation>>([]);
  @override
  final scrollController = ScrollController();
  @override
  final sortingRoomsNotifier = ValueNotifier(true);
  @override
  bool isTorBrowser = false;
  @override
  bool scrolledToTop = true;
  @override
  final activeRoomIdNotifier = ValueNotifier<String?>(null);
  @override
  late final ChatList widget = ChatList(
    activeRoomIdNotifier: activeRoomIdNotifier,
  );
  @override
  MatrixState get matrixState => _matrix;
  @override
  Client get activeClient => _client;
  @override
  Stream<Client> get clientStream => const Stream.empty();
  @override
  bool get isSelectMode => selectModeNotifier.value == SelectMode.select;
  @override
  void onClickClearSelection() {}
  @override
  void onClickAvatar() {}
  @override
  List<Widget> getSlidables(BuildContext context, Room room) => const [];
  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) =>
      '_Controller';
}

/// A client that has done its first sync, with no room of its own.
class _SyncedClient extends Client {
  _SyncedClient({required this.synced})
    : super('testclient', database: EventIdListDatabase(const []));

  final bool synced;

  @override
  String? get prevBatch => synced ? 's1' : null;
}

Future<Client> _syncedClient({bool synced = true}) async {
  final client = _SyncedClient(synced: synced);
  FakeMatrixApi.client = client;
  client.httpClient = FakeMatrixApi();
  await client.checkHomeserver(
    Uri.parse('https://fakeServer.notExisting'),
    checkWellKnown: false,
  );
  await client.init(
    newToken: 'abcd',
    newUserID: '@admin:fakeServer',
    newHomeserver: client.homeserver,
    newDeviceName: 'Text Matrix Client',
    newDeviceID: 'GHTYAJCE',
  );
  client.rooms.clear();
  return client;
}
