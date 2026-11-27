import 'package:dartz/dartz.dart' show Either, Left, Right;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_localized_locales/flutter_localized_locales.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';
import 'package:twake_chat/app_state/failure.dart';
import 'package:twake_chat/app_state/success.dart';
import 'package:twake_chat/config/localizations/localization_service.dart';
import 'package:twake_chat/config/themes.dart';
import 'package:twake_chat/di/global/get_it_initializer.dart';
import 'package:twake_chat/domain/app_state/room/delete_event_state.dart';
import 'package:twake_chat/domain/usecase/room/delete_event_interactor.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:twake_chat/presentation/mixins/delete_event_mixin.dart';
import 'package:twake_chat/utils/responsive/responsive_utils.dart';
import 'package:twake_chat/widgets/theme_builder.dart';

import '../../lenient_database.dart';

/// Records which events it was asked to delete; fails those in [failing]
/// and refuses those in [forbidden].
class _FakeDeleteEventInteractor extends DeleteEventInteractor {
  _FakeDeleteEventInteractor({
    this.failing = const {},
    this.forbidden = const {},
  });

  final Set<String> failing;
  final Set<String> forbidden;
  final deletedIds = <String>[];

  @override
  Stream<Either<Failure, Success>> execute(Event event) async* {
    deletedIds.add(event.eventId);
    if (forbidden.contains(event.eventId)) {
      yield Left(NoPermissionToDeleteEvent());
      return;
    }
    yield failing.contains(event.eventId)
        ? Left(DeleteEventFailure())
        : Right(DeleteEventSuccess());
  }
}

class _DeleteAlbumHost extends StatefulWidget {
  const _DeleteAlbumHost({required this.events});

  final List<Event> events;

  @override
  State<_DeleteAlbumHost> createState() => _DeleteAlbumHostState();
}

class _DeleteAlbumHostState extends State<_DeleteAlbumHost>
    with DeleteEventMixin {
  @override
  Widget build(BuildContext context) => Column(
    children: [
      TextButton(
        onPressed: () => deleteAlbumAction(context, widget.events),
        child: const Text('delete-album'),
      ),
      TextButton(
        onPressed: () => deleteEventsAction(context, widget.events),
        child: const Text('delete-selection'),
      ),
    ],
  );
}

late Room _room;

List<Event> _messages(int count) => [
  for (var i = 0; i < count; i++)
    Event(
      senderId: '@bob:example.com',
      type: 'm.room.message',
      room: _room,
      eventId: 'message-$i',
      content: {'msgtype': 'm.text', 'body': 'message-$i'},
      originServerTs: DateTime.utc(2026, 11, 27),
    ),
];

List<Event> _album(int count) => [
  for (var i = 0; i < count; i++)
    Event(
      senderId: '@bob:example.com',
      type: 'm.room.message',
      room: _room,
      eventId: 'image-$i',
      content: {'msgtype': 'm.image', 'body': 'image-$i.png'},
      originServerTs: DateTime.utc(2026, 11, 12),
    ),
];

void _useInteractor(DeleteEventInteractor interactor) {
  if (getIt.isRegistered<DeleteEventInteractor>()) {
    getIt.unregister<DeleteEventInteractor>();
  }
  getIt.registerSingleton<DeleteEventInteractor>(interactor);
}

Future<void> _pumpHost(WidgetTester tester, List<Event> events) async {
  await tester.pumpWidget(
    ThemeBuilder(
      builder: (context, themeMode, primaryColor) => MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: const [
          LocaleNamesLocalizationsDelegate(),
          L10n.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: LocalizationService.supportedLocales,
        theme: TwakeThemes.buildTheme(context, Brightness.light, primaryColor),
        home: Scaffold(body: _DeleteAlbumHost(events: events)),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// Pumps the host, taps it, and returns the strings the dialog uses.
Future<L10n> _pumpAndTapDelete(
  WidgetTester tester,
  List<Event> events, {
  String button = 'delete-album',
}) async {
  await _pumpHost(tester, events);
  final l10n = L10n.of(tester.element(find.byType(_DeleteAlbumHost)))!;
  await tester.tap(find.text(button));
  await tester.pumpAndSettle();
  return l10n;
}

void main() {
  setUpAll(() async {
    _room = await getLenientRoom('!delete-album:example.com');
    if (!getIt.isRegistered<ResponsiveUtils>()) {
      getIt.registerSingleton(ResponsiveUtils());
    }
  });

  testWidgets('one confirmation, then every image is deleted newest first', (
    tester,
  ) async {
    final interactor = _FakeDeleteEventInteractor();
    _useInteractor(interactor);

    final l10n = await _pumpAndTapDelete(tester, _album(3));
    expect(find.text(l10n.deleteAlbumConfirmationTitle(3)), findsOneWidget);
    expect(interactor.deletedIds, isEmpty);

    await tester.tap(find.text(l10n.delete));
    await tester.pumpAndSettle();

    // The oldest image draws the album: deleting it last keeps the bubble
    // (and its context for an error) until the end.
    expect(interactor.deletedIds, ['image-2', 'image-1', 'image-0']);
    expect(find.text(l10n.failedToDeleteMessage), findsNothing);
  });

  testWidgets('cancelling the confirmation deletes nothing', (tester) async {
    final interactor = _FakeDeleteEventInteractor();
    _useInteractor(interactor);

    final l10n = await _pumpAndTapDelete(tester, _album(3));
    await tester.tap(find.text(l10n.cancel));
    await tester.pumpAndSettle();

    expect(interactor.deletedIds, isEmpty);
  });

  testWidgets('a failed image shows the error and the rest are still deleted', (
    tester,
  ) async {
    final interactor = _FakeDeleteEventInteractor(failing: {'image-1'});
    _useInteractor(interactor);

    final l10n = await _pumpAndTapDelete(tester, _album(3));
    await tester.tap(find.text(l10n.delete));
    await tester.pumpAndSettle();

    expect(interactor.deletedIds, ['image-2', 'image-1', 'image-0']);
    expect(find.text(l10n.failedToDeleteMessage), findsOneWidget);
  });

  testWidgets('a bubble gone while the menu was open deletes nothing', (
    tester,
  ) async {
    final interactor = _FakeDeleteEventInteractor();
    _useInteractor(interactor);
    await _pumpHost(tester, _album(2));
    final host = tester.state<_DeleteAlbumHostState>(
      find.byType(_DeleteAlbumHost),
    );
    final staleContext = tester.element(find.byType(_DeleteAlbumHost));

    await tester.pumpWidget(const SizedBox());
    await host.deleteAlbumAction(staleContext, _album(2));

    expect(interactor.deletedIds, isEmpty);
  });

  group('deleteEventsAction', () {
    testWidgets('one confirmation, then every selected message is deleted', (
      tester,
    ) async {
      final interactor = _FakeDeleteEventInteractor();
      _useInteractor(interactor);

      final l10n = await _pumpAndTapDelete(
        tester,
        _messages(3),
        button: 'delete-selection',
      );
      expect(
        find.text(l10n.deleteMessagesConfirmationTitle(3)),
        findsOneWidget,
      );
      expect(interactor.deletedIds, isEmpty);

      await tester.tap(find.text(l10n.delete));
      await tester.pumpAndSettle();

      expect(interactor.deletedIds, ['message-0', 'message-1', 'message-2']);
      expect(find.text(l10n.failedToDeleteMessage), findsNothing);
    });

    testWidgets('one selected message asks the single-message question', (
      tester,
    ) async {
      _useInteractor(_FakeDeleteEventInteractor());

      final l10n = await _pumpAndTapDelete(
        tester,
        _messages(1),
        button: 'delete-selection',
      );

      expect(find.text(l10n.deleteMessageConfirmationTitle), findsOneWidget);
    });

    testWidgets('cancelling the confirmation deletes nothing', (tester) async {
      final interactor = _FakeDeleteEventInteractor();
      _useInteractor(interactor);

      final l10n = await _pumpAndTapDelete(
        tester,
        _messages(3),
        button: 'delete-selection',
      );
      await tester.tap(find.text(l10n.cancel));
      await tester.pumpAndSettle();

      expect(interactor.deletedIds, isEmpty);
    });

    testWidgets('a refused message shows the permission error once', (
      tester,
    ) async {
      final interactor = _FakeDeleteEventInteractor(
        forbidden: {'message-0', 'message-1'},
      );
      _useInteractor(interactor);

      final l10n = await _pumpAndTapDelete(
        tester,
        _messages(3),
        button: 'delete-selection',
      );
      await tester.tap(find.text(l10n.delete));
      await tester.pumpAndSettle();

      expect(interactor.deletedIds, ['message-0', 'message-1', 'message-2']);
      expect(find.text(l10n.noDeletePermissionMessage), findsOneWidget);
    });
  });
}
