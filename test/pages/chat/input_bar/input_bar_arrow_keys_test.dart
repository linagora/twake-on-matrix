import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';
import 'package:matrix/matrix.dart';
import 'package:provider/provider.dart';
import 'package:twake_chat/di/global/get_it_initializer.dart';
import 'package:twake_chat/pages/chat/input_bar/focus_suggestion_controller.dart';
import 'package:twake_chat/pages/chat/input_bar/input_bar.dart';
import 'package:twake_chat/utils/search/search_engine.dart';
import 'package:twake_chat/widgets/matrix.dart';

const _draft = 'one\ntwo\nthree';

class _FakeClient extends Fake implements Client {
  @override
  String? get userID => '@me:example.org';
}

class _FakeGroupRoom extends Fake implements Room {
  @override
  final Client client = _FakeClient();

  @override
  bool get isDirectChat => false;

  @override
  List<User> getParticipants([
    List<Membership> membershipFilter = const [
      Membership.join,
      Membership.invite,
      Membership.knock,
    ],
  ]) => [User('@bob:example.org', displayName: 'bob', room: this)];
}

class _FakeMatrixState extends Fake implements MatrixState {
  _FakeMatrixState(this.client);

  @override
  final Client client;

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) =>
      'FakeMatrixState';
}

Future<(TextEditingController, FocusNode)> _pumpDraft(
  WidgetTester tester, {
  SuggestionsController<Map<String, String?>>? suggestionsController,
}) async {
  final controller = TextEditingController();
  final focusNode = FocusNode();
  final rawKeyboardFocusNode = FocusNode();
  addTearDown(() {
    controller.dispose();
    focusNode.dispose();
    rawKeyboardFocusNode.dispose();
  });
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(extensions: [LinagoraTextThemeExtension.material()]),
      home: Scaffold(
        body: Align(
          alignment: Alignment.bottomCenter,
          child: InputBar(
            minLines: 1,
            maxLines: 8,
            controller: controller,
            typeAheadFocusNode: focusNode,
            rawKeyboardFocusNode: rawKeyboardFocusNode,
            suggestionsController: suggestionsController,
            focusSuggestionController: FocusSuggestionController(),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.byType(TextField));
  await tester.pump(const Duration(milliseconds: 200));
  await tester.enterText(find.byType(TextField), _draft);
  await tester.pump(const Duration(milliseconds: 200));
  return (controller, focusNode);
}

Future<void> _expectArrowUpMovesCaret(
  WidgetTester tester,
  TextEditingController controller,
  FocusNode focusNode,
) async {
  await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
  await tester.pump(const Duration(milliseconds: 200));

  expect(focusNode.hasFocus, isTrue);
  expect(controller.text, _draft);
  expect(controller.selection.baseOffset, 'one\ntwo'.length);
}

void main() {
  testWidgets('arrow up in a multi-line draft moves the cursor up a line', (
    tester,
  ) async {
    final suggestionsController = SuggestionsController<Map<String, String?>>();
    addTearDown(suggestionsController.dispose);
    final (controller, focusNode) = await _pumpDraft(
      tester,
      suggestionsController: suggestionsController,
    );

    expect(suggestionsController.isOpen, isFalse);
    await _expectArrowUpMovesCaret(tester, controller, focusNode);
  });

  testWidgets('arrow up moves the cursor without a suggestions controller', (
    tester,
  ) async {
    final (controller, focusNode) = await _pumpDraft(tester);

    await _expectArrowUpMovesCaret(tester, controller, focusNode);
  });

  testWidgets('arrow up moves the cursor after a tap reopens the box', (
    tester,
  ) async {
    final suggestionsController = SuggestionsController<Map<String, String?>>();
    addTearDown(suggestionsController.dispose);
    final (controller, focusNode) = await _pumpDraft(
      tester,
      suggestionsController: suggestionsController,
    );

    await tester.tap(find.byType(TextField));
    await tester.pump(const Duration(milliseconds: 200));
    controller.selection = const TextSelection.collapsed(offset: _draft.length);
    await tester.pump(const Duration(milliseconds: 200));

    expect(suggestionsController.isOpen, isFalse);
    await _expectArrowUpMovesCaret(tester, controller, focusNode);
  });

  testWidgets('typing @ after a word shows the members right away', (
    tester,
  ) async {
    if (!getIt.isRegistered<SearchEngine>()) {
      getIt.registerSingleton(const SearchEngine());
    }
    final room = _FakeGroupRoom();
    final controller = TextEditingController();
    final suggestionsController = SuggestionsController<Map<String, String?>>();
    final focusSuggestionController = FocusSuggestionController();
    addTearDown(() {
      controller.dispose();
      suggestionsController.dispose();
    });
    await tester.pumpWidget(
      Provider<MatrixState>.value(
        value: _FakeMatrixState(room.client),
        child: MaterialApp(
          theme: ThemeData(extensions: [LinagoraTextThemeExtension.material()]),
          home: Scaffold(
            body: Align(
              alignment: Alignment.bottomCenter,
              child: InputBar(
                room: room,
                controller: controller,
                suggestionsController: suggestionsController,
                focusSuggestionController: focusSuggestionController,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byType(TextField));
    await tester.pump(const Duration(milliseconds: 200));
    await tester.enterText(find.byType(TextField), 'hello');
    await tester.pump(const Duration(milliseconds: 200));
    expect(suggestionsController.isOpen, isFalse);

    await tester.enterText(find.byType(TextField), 'hello ');
    await tester.pump(const Duration(milliseconds: 200));
    await tester.enterText(find.byType(TextField), 'hello @');
    await tester.pump(const Duration(milliseconds: 200));

    expect(suggestionsController.isOpen, isTrue);
    expect(suggestionsController.suggestions, [
      containsPair('mxid', '@bob:example.org'),
    ]);
  });
}
