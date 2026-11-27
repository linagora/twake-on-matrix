import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:twake_chat/app_state/failure.dart';
import 'package:twake_chat/app_state/success.dart';
import 'package:twake_chat/domain/app_state/user_info/get_user_info_state.dart';
import 'package:twake_chat/domain/contact/entities/unified_contact.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:twake_chat/pages/chat_profile_info/chat_profile_info_details.dart';
import 'package:twake_chat/pages/contacts_tab/contacts_controller.dart';

import 'chat_profile_info_details_report_test.mocks.dart';

class _NoContacts extends ContactsController {
  @override
  Stream<List<UnifiedContact>> build() => Stream.value(const []);
}

@GenerateNiceMocks([MockSpec<Room>()])
void main() {
  late int reportTaps;
  late int leaveTaps;
  late int blockTaps;

  setUp(() {
    reportTaps = 0;
    leaveTaps = 0;
    blockTaps = 0;
  });

  MockRoom roomWith({required bool isDirectChat}) {
    final room = MockRoom();
    when(room.isDirectChat).thenReturn(isDirectChat);
    return room;
  }

  Future<void> pumpDetails(WidgetTester tester, Room room) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [contactsControllerProvider.overrideWith(_NoContacts.new)],
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: L10n.localizationsDelegates,
          supportedLocales: L10n.supportedLocales,
          home: Scaffold(
            body: SingleChildScrollView(
              child: ChatProfileInfoDetails(
                matrixId: '@bob:example.com',
                userInfoNotifier: ValueNotifier<Either<Failure, Success>>(
                  Right(GettingUserInfo()),
                ),
                isBlockedUserNotifier: ValueNotifier(false),
                blockUserLoadingNotifier: ValueNotifier(null),
                room: room,
                onReportChat: () => reportTaps++,
                onLeaveChat: () => leaveTaps++,
                onBlockUser: () => blockTaps++,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('reportChat_inADirectChat_isShown', (tester) async {
    await pumpDetails(tester, roomWith(isDirectChat: true));

    expect(
      find.byKey(ChatProfileInfoDetails.reportChatButtonKey),
      findsOneWidget,
    );
    expect(find.text('Report chat'), findsOneWidget);
  });

  testWidgets('reportChat_whenTapped_reportsWithoutLeavingOrBlocking', (
    tester,
  ) async {
    await pumpDetails(tester, roomWith(isDirectChat: true));

    await tester.tap(find.byKey(ChatProfileInfoDetails.reportChatButtonKey));
    await tester.pumpAndSettle();

    expect(reportTaps, 1);
    expect(leaveTaps, 0);
    expect(blockTaps, 0);
  });

  testWidgets('reportChat_outsideADirectChat_isHidden', (tester) async {
    await pumpDetails(tester, roomWith(isDirectChat: false));

    expect(
      find.byKey(ChatProfileInfoDetails.reportChatButtonKey),
      findsNothing,
    );
  });
}
