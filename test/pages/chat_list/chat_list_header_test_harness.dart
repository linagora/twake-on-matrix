import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:linagora_design_flutter/style/linagora_text_theme.dart';
import 'package:matrix/matrix.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart' as provider;
import 'package:twake_chat/di/global/get_it_initializer.dart';
import 'package:twake_chat/domain/spaces/room_list_entry.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:twake_chat/pages/chat_list/chat_list.dart';
import 'package:twake_chat/pages/chat_list/chat_list_header.dart';
import 'package:twake_chat/pages/chat_list/chat_list_header_style.dart';
import 'package:twake_chat/pages/chat_list/chat_list_view.dart';
import 'package:twake_chat/pages/chat_list/room_list_filter/room_list_filter_style.dart';
import 'package:twake_chat/presentation/enum/chat_list/chat_list_enum.dart';
import 'package:twake_chat/widgets/twake_components/filter_pills_style.dart';
import 'package:twake_chat/presentation/model/chat_list/chat_selection_actions.dart';
import 'package:twake_chat/providers/room_list/folded_spaces_controller.dart';
import 'package:twake_chat/providers/room_list/folders_controller.dart';
import 'package:twake_chat/providers/room_list/room_list_providers.dart';
import 'package:twake_chat/utils/responsive/responsive_utils.dart';
import 'package:twake_chat/widgets/matrix.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../../fake_client.dart';
import '../../providers/fake_active_account.dart';

// Shared by the collapsing header tests and the status bar tests.
//
// Contract for the implementer: the whole top block of the room list
// (TwakeHeader + search + filter chips) stays one `ChatListHeader`
// widget, whether it sits in the Scaffold appBar (wide layouts) or in a
// SliverAppBar of the CustomScrollView of ChatListBodyView (one column).
final headerFinder = find.byType(ChatListHeader);

const mobileSize = Size(400, 800);
const wideSize = Size(1400, 900);

/// Status bar of an iPhone with a notch, in logical pixels.
const statusBar = 47.0;

/// The phone header: app bar, new chat capsule gap, search, pills, status bar.
const headerBlockHeight =
    48 +
    ChatListHeaderStyle.newChatCapsuleGap +
    ChatListHeaderStyle.searchBarContainerHeight +
    FilterPillsStyle.height +
    statusBar;

/// What the Scaffold gives the appBar of a wide layout.
const wideHeaderBlockHeight = 120 + RoomListFilterStyle.height + statusBar;

/// Same setup before every test of a header file.
void setUpHeaderTests() {
  setUpAll(() {
    VisibilityDetectorController.instance.updateInterval = Duration.zero;
    if (!getIt.isRegistered<ResponsiveUtils>()) {
      getIt.registerSingleton(ResponsiveUtils());
    }
  });
}

/// The box the layout reserves for the header block: the app bar of the
/// SliverAppBar on the list, the SizedBox of the empty and skeleton views.
final reservedBox = find
    .ancestor(
      of: headerFinder,
      matching: find.byWidgetPredicate((w) => w is AppBar || w is SizedBox),
    )
    .first;

/// How the header is laid out: window, status bar and what the list holds.
class HeaderView {
  const HeaderView({
    this.size = mobileSize,
    this.topInset = 0,
    this.roomCount = 30,
    this.skeleton = false,
    this.bottomBarHeight = 0,
  });

  const HeaderView.phone({int roomCount = 30, bool skeleton = false})
    : this(roomCount: roomCount, skeleton: skeleton);

  const HeaderView.phoneWithStatusBar({
    int roomCount = 30,
    bool skeleton = false,
  }) : this(topInset: statusBar, roomCount: roomCount, skeleton: skeleton);

  const HeaderView.wide({double topInset = 0})
    : this(size: wideSize, topInset: topInset);

  final Size size;
  final double topInset;
  final int roomCount;

  /// No first sync yet: the skeleton is shown.
  final bool skeleton;

  /// A bottom bar this high floats over the list; 0 for none.
  final double bottomBarHeight;
}

/// The three views of the one column layout, under a status bar.
const headerBranches = <String, HeaderView>{
  'the list': HeaderView.phoneWithStatusBar(),
  'the empty list': HeaderView.phoneWithStatusBar(roomCount: 0),
  'the skeleton': HeaderView.phoneWithStatusBar(roomCount: 0, skeleton: true),
};

/// Built and on the screen.
bool headerVisible(WidgetTester tester) {
  if (headerFinder.evaluate().isEmpty) return false;
  final screen = tester.view.physicalSize / tester.view.devicePixelRatio;
  final rect = tester.getRect(headerFinder);
  return rect.bottom > 0 &&
      rect.height > 0 &&
      rect.overlaps(Offset.zero & screen) &&
      headerFinder.hitTestable().evaluate().isNotEmpty;
}

Future<void> scrollDown(WidgetTester tester, double distance) async {
  await tester.drag(find.byType(CustomScrollView), Offset(0, -distance));
  await tester.pumpAndSettle();
}

Future<void> scrollUp(WidgetTester tester, double distance) async {
  await tester.drag(find.byType(CustomScrollView), Offset(0, distance));
  await tester.pumpAndSettle();
}

final _screenKey = GlobalKey();

/// The stand-in for the floating bar, when the view has one.
const bottomBarKey = Key('bottom_bar');

/// Colour really painted at x=100, y=20: inside the status bar band, no text.
Future<Color> bandColor(WidgetTester tester) => _pixel(tester, 100, 20);

Future<Color> backgroundColor(WidgetTester tester) =>
    _pixel(tester, 2, (statusBar + 28).toInt());

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

class HeaderHarness {
  HeaderHarness(this.controller);

  final FakeChatListController controller;
  ScrollController get scroll => controller.scrollController;

  /// The user turns select mode on, without waiting for the animations.
  Future<void> startSelectMode(WidgetTester tester) async {
    controller.selectModeNotifier.value = SelectMode.select;
    await tester.pumpAndSettle();
  }

  static Future<HeaderHarness> pump(
    WidgetTester tester,
    HeaderView view,
  ) async {
    final rooms = view.roomCount;
    final skeleton = view.skeleton;
    _setView(tester, view);

    final client = (await tester.runAsync(
      () => _syncedClient(synced: !skeleton),
    ))!;
    for (var i = 0; i < rooms; i++) {
      client.rooms.add(Room(id: '!room$i:fakeServer', client: client));
    }
    final matrix = FakeMatrixState(client)..waitForFirstSync = skeleton;
    final controller = FakeChatListController(matrix, client);

    await tester.pumpWidget(
      _screen(matrix, controller, client, rooms, view.bottomBarHeight),
    );
    await _settle(tester, skeleton: skeleton);
    // Precondition of every case: without it a "hidden" check would pass on
    // a header that does not exist at all.
    expect(
      headerVisible(tester),
      isTrue,
      reason: 'the header (ChatListHeader) is on screen at the top',
    );
    return HeaderHarness(controller);
  }
}

void _setView(WidgetTester tester, HeaderView view) {
  final topInset = view.topInset;
  tester.view.physicalSize = view.size;
  tester.view.devicePixelRatio = 1;
  tester.view.padding = FakeViewPadding(top: topInset);
  tester.view.viewPadding = FakeViewPadding(top: topInset);
  addTearDown(tester.view.reset);
}

Future<void> _settle(WidgetTester tester, {required bool skeleton}) async {
  if (!skeleton) {
    await tester.pumpAndSettle();
    return;
  }
  // The skeleton shimmers for ever: pumpAndSettle would never return.
  await tester.pump(const Duration(milliseconds: 100));
  await tester.pump(const Duration(milliseconds: 100));
}

Widget _screen(
  FakeMatrixState matrix,
  FakeChatListController controller,
  Client client,
  int roomCount,
  double bottomBarHeight,
) {
  return provider.Provider<MatrixState>.value(
    value: matrix,
    child: UncontrolledProviderScope(
      container: ProviderContainer.test(
        overrides: _overrides(client, roomCount),
      ),
      child: RepaintBoundary(
        key: _screenKey,
        child: MaterialApp(
          theme: ThemeData(extensions: [LinagoraTextThemeExtension.material()]),
          locale: const Locale('en'),
          localizationsDelegates: L10n.localizationsDelegates,
          supportedLocales: L10n.supportedLocales,
          home: ChatListView(
            controller: controller,
            onTapBottomNavigation: (_) {},
            bottomNavigationBar: bottomBarHeight > 0
                ? SizedBox(key: bottomBarKey, height: bottomBarHeight)
                : null,
          ),
        ),
      ),
    ),
  );
}

List<Override> _overrides(Client client, int roomCount) {
  final entries = [
    for (var i = 0; i < roomCount; i++)
      RoomListEntry(id: '!room$i:fakeServer', name: 'Room $i'),
  ];
  return [
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
  ];
}

class _NoFold extends FoldedSpacesController {
  @override
  Future<Set<String>> build() async => <String>{};
}

class FakeMatrixState extends Mock implements MatrixState {
  FakeMatrixState(this.client);

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
      'FakeMatrixState';
}

class FakeChatListController extends Mock implements ChatListController {
  FakeChatListController(this._matrix, this._client);

  final FakeMatrixState _matrix;
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
      'FakeChatListController';
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
