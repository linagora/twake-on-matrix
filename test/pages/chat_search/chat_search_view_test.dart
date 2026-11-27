import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'
    show ProviderContainer, UncontrolledProviderScope;
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';
import 'package:matrix/matrix.dart';
import 'package:matrix/src/utils/cached_stream_controller.dart';
import 'package:provider/provider.dart' show Provider;
import 'package:twake_chat/domain/usecase/search/server_search_interactor.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:twake_chat/pages/chat_search/chat_search.dart';
import 'package:twake_chat/presentation/model/search/presentation_server_side_search.dart';
import 'package:twake_chat/providers/active_matrix_client_provider.dart';
import 'package:twake_chat/providers/matrix_client_provider.dart';
import 'package:twake_chat/utils/responsive/responsive_utils.dart';
import 'package:twake_chat/widgets/matrix.dart';

const _roomId = '!room:example.com';

class _Client extends Fake implements Client {
  late final Room room = Room(id: _roomId, client: this)
    ..setState(
      Event(
        type: EventTypes.RoomMember,
        content: {'membership': Membership.join.name, 'displayname': 'Bob'},
        stateKey: '@bob:example.com',
        senderId: '@bob:example.com',
        eventId: r'$member',
        originServerTs: DateTime(2026),
        room: Room(id: _roomId, client: this),
      ),
    );

  @override
  String get clientName => 'test';

  @override
  final onRoomState =
      CachedStreamController<({String roomId, StrippedStateEvent state})>();

  @override
  bool get formatLocalpart => false;

  @override
  bool get autoRequestProfileForMissingUsers => false;

  @override
  bool get mxidLocalPartFallback => true;

  @override
  Room? getRoomById(String id) => id == _roomId ? room : null;
}

class _MatrixState extends Fake implements MatrixState {
  _MatrixState(this.client);

  @override
  final Client client;

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) =>
      '_MatrixState';
}

class _ServerSearchInteractor extends Fake implements ServerSearchInteractor {}

void main() {
  setUpAll(() {
    GetIt.instance
      ..registerSingleton(ResponsiveUtils())
      ..registerSingleton<ServerSearchInteractor>(_ServerSearchInteractor());
  });

  tearDownAll(() => GetIt.instance.reset());

  testWidgets('shows a result without the "You" label when no account is '
      'active', (tester) async {
    final client = _Client();
    final container = ProviderContainer.test(
      retry: (_, _) => null,
      overrides: [
        matrixClientProvider.overrideWithValue(client),
        activeMatrixClientProvider.overrideWithValue(null),
      ],
    );
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: Provider<MatrixState>.value(
          value: _MatrixState(client),
          child: MaterialApp(
            theme: ThemeData(
              extensions: [LinagoraTextThemeExtension.material()],
            ),
            locale: const Locale('en'),
            localizationsDelegates: L10n.localizationsDelegates,
            supportedLocales: L10n.supportedLocales,
            home: const ChatSearch(roomId: _roomId, isInStack: false),
          ),
        ),
      ),
    );

    tester
        .state<ChatSearchController>(find.byType(ChatSearch))
        .serverSearchController
        .searchResultsNotifier
        .value = PresentationServerSideSearch(
      searchResults: [
        Result(
          result: MatrixEvent(
            type: EventTypes.Message,
            content: {'msgtype': MessageTypes.Text, 'body': 'hello'},
            senderId: '@bob:example.com',
            eventId: r'$event',
            originServerTs: DateTime(2026),
            roomId: _roomId,
          ),
        ),
      ],
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('Bob'), findsOneWidget);
  });
}
