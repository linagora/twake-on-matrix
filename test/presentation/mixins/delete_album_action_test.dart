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

/// Records which events it was asked to delete; fails those in [failing].
class _FakeDeleteEventInteractor extends DeleteEventInteractor {
  _FakeDeleteEventInteractor({this.failing = const {}});

  final Set<String> failing;
  final deletedIds = <String>[];

  @override
  Stream<Either<Failure, Success>> execute(Event event) async* {
    deletedIds.add(event.eventId);
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
  Widget build(BuildContext context) => TextButton(
    onPressed: () => deleteAlbumAction(context, widget.events),
    child: const Text('delete-album'),
  );
}

late Room _room;

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

/// Pumps the host, taps it, and returns the strings the dialog uses.
Future<L10n> _pumpAndTapDelete(WidgetTester tester, List<Event> events) async {
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
  final l10n = L10n.of(tester.element(find.byType(_DeleteAlbumHost)))!;
  await tester.tap(find.text('delete-album'));
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

  testWidgets('one confirmation, then every image is deleted in order', (
    tester,
  ) async {
    final interactor = _FakeDeleteEventInteractor();
    _useInteractor(interactor);

    final l10n = await _pumpAndTapDelete(tester, _album(3));
    expect(find.text(l10n.deleteAlbumConfirmationTitle(3)), findsOneWidget);
    expect(interactor.deletedIds, isEmpty);

    await tester.tap(find.text(l10n.delete));
    await tester.pumpAndSettle();

    expect(interactor.deletedIds, ['image-0', 'image-1', 'image-2']);
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

    expect(interactor.deletedIds, ['image-0', 'image-1', 'image-2']);
    expect(find.text(l10n.failedToDeleteMessage), findsOneWidget);
  });
}
