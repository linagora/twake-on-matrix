import 'package:dartz/dartz.dart';
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/domain/app_state/room/create_new_group_chat_state.dart';
import 'package:fluffychat/domain/app_state/room/invite_user_state.dart';
import 'package:fluffychat/pages/new_group/new_group_chat_info.dart';
import 'package:fluffychat/pages/new_group/new_group_chat_info_view.dart';
import 'package:fluffychat/presentation/extensions/value_notifier_custom.dart';
import 'package:fluffychat/presentation/model/contact/presentation_contact.dart';
import 'package:fluffychat/utils/responsive/responsive_utils.dart';
import 'package:fluffychat/widgets/app_bars/twake_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluffychat/generated/l10n/app_localizations.dart';
import 'package:get_it/get_it.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'new_group_chat_info_test.mocks.dart';

@GenerateNiceMocks([MockSpec<NewGroupChatInfoController>()])
void main() {
  final getIt = GetIt.instance;

  late MockNewGroupChatInfoController mockController;

  setUpAll(() {
    // Register ResponsiveUtils for the view
    if (!getIt.isRegistered<ResponsiveUtils>()) {
      getIt.registerSingleton(ResponsiveUtils());
    }
  });

  setUp(() {
    mockController = MockNewGroupChatInfoController();

    // Setup default mock values for controller properties
    when(
      mockController.enableEncryptionNotifier,
    ).thenReturn(ValueNotifier(false));
    when(mockController.haveGroupNameNotifier).thenReturn(ValueNotifier(false));
    when(mockController.createRoomStateNotifier).thenReturn(
      ValueNotifier<Either<Failure, Success>>(Right(CreateNewGroupInitial())),
    );
    when(mockController.inviteUserStateNotifier).thenReturn(
      ValueNotifier<Either<Failure, Success>>(Right(InviteUserInitial())),
    );
    when(
      mockController.groupNameTextEditingController,
    ).thenReturn(TextEditingController());
    when(mockController.groupNameFocusNode).thenReturn(FocusNode());
    when(mockController.contactsList).thenReturn(<PresentationContact>{});
    when(mockController.isCreatingRoom).thenReturn(false);
    when(mockController.getErrorMessage(any)).thenReturn(null);
    when(
      mockController.avatarAssetEntityNotifier,
    ).thenReturn(ValueNotifier(null));
    when(mockController.pickAvatarUIState).thenReturn(
      ValueNotifierCustom<Either<Failure, Success>>(
        Right(CreateNewGroupInitial()),
      ),
    );
    when(
      mockController.responsiveUtils,
    ).thenReturn(getIt.get<ResponsiveUtils>());
  });

  tearDownAll(() {
    getIt.reset();
  });

  group('NewGroupChatInfo AppBar verification - widget test', () {
    testWidgets('verify TwakeAppBar inside NewGroupChatInfoView', (
      WidgetTester tester,
    ) async {
      // Pump NewGroupChatInfoView directly with mock controller
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: L10n.localizationsDelegates,
          supportedLocales: L10n.supportedLocales,
          home: NewGroupChatInfoView(mockController),
        ),
      );

      // Wait for widget to build
      await tester.pumpAndSettle();

      // Verify TwakeAppBar exists inside NewGroupChatInfoView
      expect(find.byType(TwakeAppBar), findsOneWidget);

      // Get the TwakeAppBar widget
      final twakeAppBar = tester.widget<TwakeAppBar>(find.byType(TwakeAppBar));

      // Verify TwakeAppBar properties
      expect(twakeAppBar.centerTitle, isTrue);
      expect(twakeAppBar.withDivider, isTrue);
      expect(twakeAppBar.enableLeftTitle, isTrue);

      // Verify title text
      final context = tester.element(find.byType(TwakeAppBar));
      expect(twakeAppBar.title, equals(L10n.of(context)!.newGroupChat));

      // Verify back button icon
      expect(find.byIcon(Icons.arrow_back_ios), findsOneWidget);
    });
  });
}
