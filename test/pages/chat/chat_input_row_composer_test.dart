import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:linagora_design_flutter/style/linagora_text_theme.dart';
import 'package:matrix/matrix.dart';
import 'package:scroll_to_index/scroll_to_index.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:twake_chat/config/setting_keys.dart';
import 'package:twake_chat/di/global/get_it_initializer.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:twake_chat/pages/chat/chat.dart';
import 'package:twake_chat/pages/chat/chat_input_row.dart';
import 'package:twake_chat/pages/chat/chat_input_row_mobile.dart';
import 'package:twake_chat/pages/chat/chat_input_row_send_btn.dart';
import 'package:twake_chat/pages/chat/chat_input_row_web.dart';
import 'package:twake_chat/pages/chat/input_bar/focus_suggestion_controller.dart';
import 'package:twake_chat/presentation/mixins/audio_mixin.dart';
import 'package:twake_chat/utils/responsive/responsive_utils.dart';
import 'package:twake_chat/utils/search/search_engine.dart';

import '../../fake_client.dart';

// Which message field a chat gets (review of #3843): the compact composer is
// for a wide screen; a phone keeps its own row, whatever the device stored.

const _phone = Size(390, 844);
const _wide = Size(1200, 900);

class _Client extends Client {
  _Client()
    : super(
        'chat-input-row-composer-test',
        httpClient: FakeMatrixApi(),
        database: MockDatabase(),
      );

  @override
  String? get userID => '@me:example.org';
}

/// An open chat with nothing typed, no reply, no edit, no recording.
class _Chat extends Fake implements ChatController {
  _Chat(this.room);

  @override
  final Room room;

  @override
  Timeline? get timeline => null;

  @override
  bool get selectMode => false;

  @override
  bool get isThread => false;

  @override
  final responsive = getIt.get<ResponsiveUtils>();

  @override
  final audioRecordStateNotifier = ValueNotifier(AudioRecordState.initial);

  @override
  final recordDurationWebNotifier = ValueNotifier(0);

  @override
  final sendController = TextEditingController();

  @override
  final inputText = ValueNotifier('');

  @override
  final editEventNotifier = ValueNotifier<Event?>(null);

  @override
  final replyEventNotifier = ValueNotifier<Event?>(null);

  @override
  final showEmojiPickerNotifier = ValueNotifier(false);

  @override
  final chatComposerTypeAheadKey = const ValueKey<String>('composer');

  @override
  final rawKeyboardListenerFocusNode = FocusNode();

  @override
  FocusNode inputFocus = FocusNode();

  @override
  SuggestionsController<Map<String, String?>> suggestionsController =
      SuggestionsController();

  @override
  final focusSuggestionController = FocusSuggestionController();

  @override
  AutoScrollController suggestionScrollController = AutoScrollController();

  @override
  void replaceDraft(String text) {}

  @override
  void onInputBarChanged(String text) {}

  @override
  void onInputBarSubmitted() {}

  @override
  void onPasteImages(List<MatrixFile> images) {}

  @override
  void onEmojiAction(TapDownDetails tapDownDetails) {}

  @override
  void cancelEditEventAction() {}

  @override
  void onSendFileClick(BuildContext context) {}

  @override
  Future<void> onTapRecorderWeb({required BuildContext context}) async {}

  @override
  Future<void> discardRecordWeb() async {}

  @override
  Future<void> sendVoiceMessageWeb() async {}

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) => '_Chat';
}

/// The message field of a chat on a screen of [size], the composer style
/// stored as [composerStyle].
Future<void> _pumpField(
  WidgetTester tester, {
  required Size size,
  required String composerStyle,
}) async {
  SharedPreferences.setMockInitialValues({
    SettingKeys.composerStyle: composerStyle,
  });
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final chat = _Chat(Room(id: '!room:example.org', client: _Client()));
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        theme: ThemeData(extensions: [LinagoraTextThemeExtension.material()]),
        locale: const Locale('en'),
        localizationsDelegates: L10n.localizationsDelegates,
        supportedLocales: L10n.supportedLocales,
        home: Scaffold(
          body: Align(
            alignment: Alignment.bottomCenter,
            child: ChatInputRow(chat),
          ),
        ),
      ),
    ),
  );
  for (var i = 0; i < 4; i++) {
    await tester.pump(const Duration(milliseconds: 250));
  }
}

Finder get _sendButton => find.byType(ChatInputRowSendBtn);

void main() {
  setUp(() {
    getIt
      ..registerSingleton(ResponsiveUtils())
      ..registerSingleton(const SearchEngine());
  });
  tearDown(() async => getIt.reset());

  group('a wide screen with the compact composer', () {
    testWidgets('has one send button, inside the composer', (tester) async {
      await _pumpField(tester, size: _wide, composerStyle: 'compact');

      expect(_sendButton, findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(ChatInputRowWeb),
          matching: _sendButton,
        ),
        findsOneWidget,
      );
    });
  });

  group('a wide screen with the classic bar', () {
    testWidgets('keeps the send button outside the field, at its right', (
      tester,
    ) async {
      await _pumpField(tester, size: _wide, composerStyle: 'classic');

      expect(_sendButton, findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(ChatInputRowWeb),
          matching: _sendButton,
        ),
        findsNothing,
      );
    });
  });

  group('a phone that stored the compact composer', () {
    testWidgets('still gets the row of a phone', (tester) async {
      await _pumpField(tester, size: _phone, composerStyle: 'compact');

      expect(find.byType(ChatInputRowMobile), findsOneWidget);
      expect(find.byType(ChatInputRowWeb), findsNothing);
    });

    testWidgets('keeps one send button, outside the field', (tester) async {
      await _pumpField(tester, size: _phone, composerStyle: 'compact');

      expect(_sendButton, findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(ChatInputRowMobile),
          matching: _sendButton,
        ),
        findsNothing,
      );
    });
  });
}
