import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';
import 'package:matrix/matrix.dart';
import 'package:provider/provider.dart';
import 'package:twake_chat/di/global/get_it_initializer.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:twake_chat/pages/chat/input_bar/focus_suggestion_controller.dart';
import 'package:twake_chat/pages/chat/input_bar/input_bar.dart';
import 'package:twake_chat/utils/search/search_engine.dart';
import 'package:twake_chat/widgets/matrix.dart';

class _FakeClient extends Fake implements Client {
  @override
  String? get userID => '@me:example.org';
}

class _FakeGroupRoom extends Fake implements Room {
  _FakeGroupRoom({required this.canNotifyRoom});

  final bool canNotifyRoom;

  @override
  final Client client = _FakeClient();

  @override
  bool get isDirectChat => false;

  @override
  bool canSendNotification(String userid, {String notificationType = 'room'}) =>
      userid == client.userID && notificationType == 'room' && canNotifyRoom;

  @override
  List<User> getParticipants([
    List<Membership> membershipFilter = const [
      Membership.join,
      Membership.invite,
      Membership.knock,
    ],
  ]) => [
    User('@bob:example.org', displayName: 'bob', room: this),
    User('@robert:example.org', displayName: 'robert', room: this),
  ];
}

class _FakeMatrixState extends Fake implements MatrixState {
  _FakeMatrixState(this.client);

  @override
  final Client client;

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) =>
      'FakeMatrixState';
}

Future<(TextEditingController, SuggestionsController<Map<String, String?>>)>
_pumpInputBar(WidgetTester tester, {required bool canNotifyRoom}) async {
  if (!getIt.isRegistered<SearchEngine>()) {
    getIt.registerSingleton(const SearchEngine());
  }
  final room = _FakeGroupRoom(canNotifyRoom: canNotifyRoom);
  final controller = TextEditingController();
  final suggestionsController = SuggestionsController<Map<String, String?>>();
  addTearDown(() {
    controller.dispose();
    suggestionsController.dispose();
  });
  await tester.pumpWidget(
    Provider<MatrixState>.value(
      value: _FakeMatrixState(room.client),
      child: MaterialApp(
        localizationsDelegates: L10n.localizationsDelegates,
        supportedLocales: L10n.supportedLocales,
        theme: ThemeData(extensions: [LinagoraTextThemeExtension.material()]),
        home: Scaffold(
          body: Align(
            alignment: Alignment.bottomCenter,
            child: InputBar(
              room: room,
              controller: controller,
              suggestionsController: suggestionsController,
              focusSuggestionController: FocusSuggestionController(),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.byType(TextField));
  await tester.pump(const Duration(milliseconds: 200));
  return (controller, suggestionsController);
}

Future<void> _type(WidgetTester tester, String text) async {
  await tester.enterText(find.byType(TextField), text);
  await tester.pump(const Duration(milliseconds: 200));
}

List<String?> _mentions(
  SuggestionsController<Map<String, String?>> suggestionsController,
) => [
  for (final suggestion in suggestionsController.suggestions ?? [])
    suggestion['mention'],
];

void main() {
  testWidgets('a bare @ offers @room after the members', (tester) async {
    final (_, suggestions) = await _pumpInputBar(tester, canNotifyRoom: true);

    await _type(tester, '@');

    expect(_mentions(suggestions), ['@bob', '@robert', '@room']);
  });

  testWidgets('a word of room, all or everyone puts @room first', (
    tester,
  ) async {
    final (_, suggestions) = await _pumpInputBar(tester, canNotifyRoom: true);

    await _type(tester, '@ro');
    expect(_mentions(suggestions), ['@room', '@robert']);

    await _type(tester, '@every');
    expect(_mentions(suggestions), ['@room']);

    await _type(tester, '@bo');
    expect(_mentions(suggestions), ['@bob']);
  });

  testWidgets('no @room without the power level to notify the room', (
    tester,
  ) async {
    final (_, suggestions) = await _pumpInputBar(tester, canNotifyRoom: false);

    await _type(tester, '@');
    expect(_mentions(suggestions), ['@bob', '@robert']);

    await _type(tester, '@ro');
    expect(_mentions(suggestions), ['@robert']);
  });

  testWidgets('picking @room writes it in the message', (tester) async {
    final (controller, suggestions) = await _pumpInputBar(
      tester,
      canNotifyRoom: true,
    );

    await _type(tester, 'hi @ro');
    final typeAhead = tester.widget<TypeAheadField<Map<String, String?>>>(
      find.byType(TypeAheadField<Map<String, String?>>),
    );
    expect(find.text('Notify everyone in the conversation'), findsOneWidget);
    typeAhead.onSelected!(suggestions.suggestions!.first);
    await tester.pump(const Duration(milliseconds: 200));

    expect(controller.text, 'hi @room ');
  });
}
