import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/di/global/get_it_initializer.dart';
import 'package:twake_chat/domain/drive/entities/drive_config.dart';
import 'package:twake_chat/domain/drive/entities/drive_id_token.dart';
import 'package:twake_chat/domain/drive/entities/drive_session.dart';
import 'package:twake_chat/domain/scribe/entities/scribe_prompt.dart';
import 'package:twake_chat/domain/scribe/entities/scribe_room.dart';
import 'package:twake_chat/domain/scribe/exceptions/scribe_exception.dart';
import 'package:twake_chat/domain/scribe/sources/scribe_source.dart';
import 'package:twake_chat/domain/scribe/usecases/rewrite_draft_usecase.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:twake_chat/pages/scribe/providers/scribe_room_provider.dart';
import 'package:twake_chat/pages/scribe/widgets/scribe_button.dart';
import 'package:twake_chat/providers/drive_config_provider.dart';
import 'package:twake_chat/providers/drive_session_provider.dart';
import 'package:twake_chat/providers/rewrite_draft_usecase_provider.dart';
import 'package:twake_chat/utils/responsive/responsive_utils.dart';

const _roomId = '!room:example.com';
const _configured = DriveConfig(
  ssoUrl: 'https://sso.example',
  ssoClientId: 'c',
);
const _notConfigured = DriveConfig(ssoUrl: '', ssoClientId: 'c');
const _clearRoom = ScribeRoom(
  isEncrypted: false,
  isDirect: false,
  scribeEnabled: false,
);

final _session = DriveSession(
  idToken: DriveIdToken(value: 'id', expiresAt: DateTime.utc(2100)),
  platformUrl: Uri.parse('https://alice.twake.example'),
);

/// Answers each rewrite with the next result the test gives.
class _Source implements ScribeSource {
  final prompts = <(ScribePrompt, String)>[];
  Completer<String> answer = Completer();

  @override
  Future<String> rewrite({
    required DriveSession session,
    required Future<DriveSession> Function() renewSession,
    required ScribePrompt prompt,
    required String draft,
  }) {
    prompts.add((prompt, draft));
    return answer.future;
  }
}

class _SignedIn extends DriveSessionNotifier {
  @override
  DriveSession? build() => _session;
}

/// Not signed in until the test calls [signIn].
class _SignsInLater extends DriveSessionNotifier {
  @override
  DriveSession? build() => null;

  void signIn() => state = _session;
}

void main() {
  late _Source source;
  late TextEditingController draft;
  late List<String> rewritten;

  setUp(() {
    // The snackbar reads its width from the responsive helper.
    getIt.registerSingleton<ResponsiveUtils>(ResponsiveUtils());
    source = _Source();
    draft = TextEditingController(text: 'hi emery how are you?');
    rewritten = [];
  });

  tearDown(() async {
    draft.dispose();
    await getIt.reset();
  });

  Future<void> pumpButton(
    WidgetTester tester, {
    // Null: the room cannot be read.
    ScribeRoom? room = _clearRoom,
    DriveConfig config = _configured,
    DriveSessionNotifier Function() sessionOf = _SignedIn.new,
  }) async {
    // Made inside the test, so its answer arrives on the test's fake clock.
    source.answer = Completer();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          driveConfigProvider.overrideWithValue(config),
          driveSessionProvider.overrideWith(sessionOf),
          scribeRoomProvider(_roomId).overrideWith(
            (ref) => room == null
                ? Stream.error(const ScribeRoomNotFound())
                : Stream.value(room),
          ),
          rewriteDraftUseCaseProvider.overrideWithValue(
            RewriteDraftUseCase(
              source: source,
              obtainSession: () async => _session,
              renewSession: () async => _session,
              currentAccount: () => '@alice:example.com',
            ),
          ),
        ],
        child: MaterialApp(
          localizationsDelegates: L10n.localizationsDelegates,
          supportedLocales: L10n.supportedLocales,
          home: Scaffold(
            body: Align(
              alignment: Alignment.bottomLeft,
              child: ScribeButton(
                roomId: _roomId,
                draft: draft,
                onRewritten: rewritten.add,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> openMenu(WidgetTester tester) async {
    await tester.tap(find.byIcon(Icons.auto_awesome));
    await tester.pumpAndSettle();
  }

  MenuItemButton item(WidgetTester tester, String label) => tester.widget(
    find.ancestor(of: find.text(label), matching: find.byType(MenuItemButton)),
  );

  /// Runs a menu action; a tap would run it only after the next frame.
  Future<void> pick(WidgetTester tester, String label) async {
    item(tester, label).onPressed!();
    await tester.pump();
  }

  /// Gives the Scribe's answer, then draws the composer again (without
  /// waiting for the snackbar to go away).
  Future<void> answer(
    WidgetTester tester,
    void Function(Completer<String> answer) give,
  ) async {
    give(source.answer);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
  }

  testWidgets('is hidden where the room does not offer the Scribe', (
    tester,
  ) async {
    await pumpButton(
      tester,
      room: const ScribeRoom(
        isEncrypted: true,
        isDirect: true,
        scribeEnabled: true,
      ),
    );

    expect(find.byIcon(Icons.auto_awesome), findsNothing);
  });

  testWidgets('is hidden when the room cannot be read', (tester) async {
    await pumpButton(tester, room: null);

    expect(find.byIcon(Icons.auto_awesome), findsNothing);
  });

  testWidgets('is hidden without a workplace', (tester) async {
    await pumpButton(tester, config: _notConfigured);

    expect(find.byIcon(Icons.auto_awesome), findsNothing);
  });

  testWidgets('offers the five actions of Chat web', (tester) async {
    await pumpButton(tester);
    await openMenu(tester);

    for (final label in [
      'Correct',
      'Improve',
      'Tone',
      'Translate',
      'Summarize',
    ]) {
      expect(item(tester, label).onPressed, isNotNull, reason: label);
    }
  });

  testWidgets('disables every action on a blank draft', (tester) async {
    draft.text = '   ';
    await pumpButton(tester);
    await openMenu(tester);

    for (final label in [
      'Correct',
      'Improve',
      'Tone',
      'Translate',
      'Summarize',
    ]) {
      expect(item(tester, label).onPressed, isNull, reason: label);
    }
  });

  testWidgets('a submenu replaces the menu, and its header goes back', (
    tester,
  ) async {
    await pumpButton(tester);
    await openMenu(tester);

    await tester.tap(find.text('Translate'));
    await tester.pumpAndSettle();

    expect(find.text('Correct'), findsNothing);
    expect(find.text('Vietnamese'), findsOneWidget);

    await tester.tap(find.text('Translate'));
    await tester.pumpAndSettle();

    expect(find.text('Correct'), findsOneWidget);
    expect(find.text('Vietnamese'), findsNothing);
  });

  testWidgets('shows progress, then replaces the draft with the result', (
    tester,
  ) async {
    await pumpButton(tester);
    await openMenu(tester);

    await tester.tap(find.text('Tone'));
    await tester.pumpAndSettle();
    await pick(tester, 'Polite');

    expect(source.prompts, [
      (ScribePrompt.changeTonePolite, 'hi emery how are you?'),
    ]);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byIcon(Icons.auto_awesome), findsNothing);

    await answer(tester, (answer) => answer.complete('Hi Emery, how are you?'));

    expect(rewritten, ['Hi Emery, how are you?']);
    expect(find.byIcon(Icons.auto_awesome), findsOneWidget);
  });

  testWidgets('a failure keeps the draft and says so', (tester) async {
    await pumpButton(tester);
    await openMenu(tester);

    await pick(tester, 'Correct');
    await answer(
      tester,
      (answer) => answer.completeError(const ScribeRewriteFailed()),
    );

    expect(rewritten, isEmpty);
    expect(
      find.text("Couldn't rewrite your message. Try again."),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.auto_awesome), findsOneWidget);
  });

  testWidgets('text typed during the rewrite is kept', (tester) async {
    await pumpButton(tester);
    await openMenu(tester);

    await pick(tester, 'Summarize');
    draft.text = 'something else';
    await answer(tester, (answer) => answer.complete('A summary'));

    expect(rewritten, isEmpty);
  });

  testWidgets('a result after the composer closed is dropped', (tester) async {
    await pumpButton(tester);
    await openMenu(tester);

    await pick(tester, 'Correct');
    await tester.pumpWidget(const SizedBox());
    await answer(tester, (answer) => answer.complete('Hi Emery'));

    expect(rewritten, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a failure after the composer closed shows nothing', (
    tester,
  ) async {
    await pumpButton(tester);
    await openMenu(tester);

    await pick(tester, 'Correct');
    await tester.pumpWidget(const SizedBox());
    await answer(
      tester,
      (answer) => answer.completeError(const ScribeRewriteFailed()),
    );

    expect(tester.takeException(), isNull);
  });

  testWidgets('an encrypted group says where the draft goes', (tester) async {
    await pumpButton(
      tester,
      room: const ScribeRoom(
        isEncrypted: true,
        isDirect: false,
        scribeEnabled: true,
      ),
    );
    await openMenu(tester);

    expect(
      find.text('Sent outside the encryption to alice.twake.example'),
      findsOneWidget,
    );
  });

  testWidgets('the notice names the workplace once the session arrives', (
    tester,
  ) async {
    await pumpButton(
      tester,
      room: const ScribeRoom(
        isEncrypted: true,
        isDirect: false,
        scribeEnabled: true,
      ),
      sessionOf: _SignsInLater.new,
    );
    await openMenu(tester);
    expect(find.text('Sent outside the encryption'), findsOneWidget);

    final container = ProviderScope.containerOf(
      tester.element(find.byType(ScribeButton)),
    );
    (container.read(driveSessionProvider.notifier) as _SignsInLater).signIn();
    await tester.pump();

    expect(
      find.text('Sent outside the encryption to alice.twake.example'),
      findsOneWidget,
    );
  });

  testWidgets('a clear room shows no notice', (tester) async {
    await pumpButton(tester);
    await openMenu(tester);

    expect(find.textContaining('Sent outside the encryption'), findsNothing);
  });
}
