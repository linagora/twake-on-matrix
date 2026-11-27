import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' hide Provider;
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';
import 'package:matrix/matrix.dart';
import 'package:matrix/src/utils/cached_stream_controller.dart';
import 'package:provider/provider.dart' show Provider;
import 'package:twake_chat/data/contact/datasources/matrix_profile_datasource.dart';
import 'package:twake_chat/domain/presence/entities/person_presence.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:twake_chat/pages/contacts_tab/providers/matrix_profile_providers.dart';
import 'package:twake_chat/presentation/enum/chat_list/chat_list_enum.dart';
import 'package:twake_chat/presentation/model/chat_list/chat_selection_actions.dart';
import 'package:twake_chat/presentation/widget_keys/navigation_keys.dart';
import 'package:twake_chat/providers/active_user_id_provider.dart';
import 'package:twake_chat/providers/matrix_client_provider.dart';
import 'package:twake_chat/providers/person_presence_provider.dart';
import 'package:twake_chat/utils/responsive/responsive_utils.dart';
import 'package:twake_chat/widgets/matrix.dart';
import 'package:twake_chat/widgets/twake_components/twake_header.dart';
import 'package:twake_chat/widgets/twake_components/twake_header_account_avatar.dart';

class _FakeClient extends Fake implements Client {
  @override
  final CachedStreamController<BasicEvent> onAccountData =
      CachedStreamController();
}

class _FakeMatrix extends Fake implements MatrixState {
  _FakeMatrix(this.client);

  @override
  final Client client;

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) =>
      '_FakeMatrix';
}

const _me = '@alice:example.org';

final _avatar = find.byKey(NavigationKeys.accountAvatar.key);

class _Header {
  const _Header({
    this.width = 400,
    this.displayName = 'Alice Martin',
    this.presence,
    this.mode = SelectMode.normal,
  });

  final double width;
  final String? displayName;
  final PersonPresence? presence;
  final SelectMode mode;
}

Future<List<String>> _pumpHeader(
  WidgetTester tester, [
  _Header header = const _Header(),
]) async {
  tester.view.physicalSize = Size(header.width, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final selectMode = ValueNotifier(header.mode);
  final selection = ValueNotifier<List<ConversationSelectionPresentation>>(
    const [],
  );
  addTearDown(selectMode.dispose);
  addTearDown(selection.dispose);
  final taps = <String>[];
  final client = _FakeClient();
  await tester.pumpWidget(
    ProviderScope(
      retry: (_, _) => null,
      overrides: [
        matrixClientProvider.overrideWithValue(client),
        activeUserIdProvider.overrideWithValue(_me),
        matrixUserProfileProvider(_me).overrideWith(
          (ref) async =>
              MatrixUserProfile(matrixId: _me, displayName: header.displayName),
        ),
        personPresenceProvider(
          _me,
        ).overrideWith((ref) => Stream.value(header.presence)),
      ],
      child: Provider<MatrixState>.value(
        value: _FakeMatrix(client),
        child: MaterialApp(
          theme: ThemeData(extensions: [LinagoraTextThemeExtension.material()]),
          locale: const Locale('en'),
          localizationsDelegates: L10n.localizationsDelegates,
          supportedLocales: L10n.supportedLocales,
          home: Scaffold(
            appBar: TwakeHeader(
              onClearSelection: () {},
              client: client,
              selectModeNotifier: selectMode,
              conversationSelectionNotifier: selection,
              onClickAvatar: () => taps.add('settings'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return taps;
}

void main() {
  setUp(() => GetIt.instance.registerSingleton(ResponsiveUtils()));
  tearDown(() => GetIt.instance.reset());

  group('account avatar in the Chats header', () {
    _lookAndActionTests();
    _stateTests();
  });
}

void _lookAndActionTests() {
  testWidgets('shows the initials of the active account, left of the '
      'centred title', (tester) async {
    await _pumpHeader(tester);

    expect(find.byType(TwakeHeaderAccountAvatar), findsOneWidget);
    expect(
      find.descendant(of: _avatar, matching: find.text('AM')),
      findsOneWidget,
    );
    final avatar = tester.getRect(_avatar);
    expect(avatar.center.dx, lessThan(tester.getCenter(find.text('Chats')).dx));
    expect(tester.getCenter(find.text('Chats')).dx, moreOrLessEquals(200));
  });

  testWidgets('without a display name, the initials come from the user id', (
    tester,
  ) async {
    await _pumpHeader(tester, const _Header(displayName: null));

    expect(
      find.descendant(of: _avatar, matching: find.text('A')),
      findsOneWidget,
    );
  });

  testWidgets('a tap opens the settings', (tester) async {
    final taps = await _pumpHeader(tester);

    await tester.tap(_avatar);

    expect(taps, ['settings']);
  });

  testWidgets('is a 44 pt button labelled Settings', (tester) async {
    final semantics = tester.ensureSemantics();
    await _pumpHeader(tester);

    expect(tester.getSize(_avatar), const Size.square(44));
    expect(
      tester.getSemantics(_avatar),
      matchesSemantics(
        label: 'Settings',
        isButton: true,
        hasTapAction: true,
        isFocusable: true,
        hasFocusAction: true,
      ),
    );
    semantics.dispose();
  });
}

void _stateTests() {
  testWidgets('carries the presence dot of the account', (tester) async {
    await _pumpHeader(
      tester,
      const _Header(presence: PersonPresence(status: PresenceStatus.online)),
    );

    expect(
      tester
          .widget<LinagoraPresenceBadge>(find.byType(LinagoraPresenceBadge))
          .presence,
      LinagoraPresence.online,
    );
  });

  testWidgets('is not in the select mode app bar', (tester) async {
    await _pumpHeader(tester, const _Header(mode: SelectMode.select));

    expect(_avatar, findsNothing);
  });

  testWidgets('is not on desktop, where the rail has Settings', (tester) async {
    await _pumpHeader(tester, const _Header(width: 1400));

    expect(_avatar, findsNothing);
  });
}
