import 'package:dartz/dartz.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/domain/app_state/contact/get_contacts_state.dart';
import 'package:fluffychat/domain/app_state/contact/get_phonebook_contact_state.dart';
import 'package:fluffychat/domain/contact_manager/contacts_manager.dart';
import 'package:fluffychat/domain/usecase/search/search_recent_chat_interactor.dart';
import 'package:fluffychat/generated/l10n/app_localizations.dart';
import 'package:fluffychat/pages/contacts_tab/contacts_tab.dart';
import 'package:fluffychat/pages/contacts_tab/widgets/sliver_empty_contacts.dart';
import 'package:fluffychat/pages/contacts_tab/widgets/sliver_loading_contacts.dart';
import 'package:fluffychat/pages/new_private_chat/widget/loading_contact_widget.dart';
import 'package:fluffychat/pages/new_private_chat/widget/no_contacts_found.dart';
import 'package:fluffychat/presentation/mixins/contacts_view_controller_mixin.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';
import 'package:mockito/mockito.dart';

class MockContactsManager extends Mock implements ContactsManager {
  Object? cancelSubscriptionsError;
  bool cancelSubscriptionsCalled = false;

  @override
  Future<void> cancelAllSubscriptions() async {
    cancelSubscriptionsCalled = true;
    if (cancelSubscriptionsError case final error?) {
      throw error;
    }
  }
}

class MockClient extends Mock implements Client {}

class MockBuildContext extends Mock implements BuildContext {}

class MockMatrixLocalizations extends Mock implements MatrixLocalizations {}

class TestContactsTabController extends Mock
    with ContactsViewControllerMixin
    implements ContactsTabController {
  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) =>
      runtimeType.toString();
}

void main() {
  late MockContactsManager contactsManager;
  late TestContactsTabController controller;

  setUp(() {
    contactsManager = MockContactsManager();
    getIt.registerSingleton<SearchRecentChatInteractor>(
      SearchRecentChatInteractor(),
    );
    getIt.registerSingleton<ContactsManager>(contactsManager);
    controller = TestContactsTabController();
  });

  tearDown(() async {
    controller.disposeContactsMixin();
    await getIt.reset();
  });

  testWidgets('shows the empty search state from the real contact notifiers', (
    tester,
  ) async {
    controller.presentationContactNotifier.value = const Right(
      ContactsInitial(),
    );
    controller.presentationPhonebookContactNotifier.value = const Right(
      GetPhonebookContactsInitial(),
    );
    controller.presentationRecentContactNotifier.value = [];
    controller.textEditingController.text = 'missing';

    expect(controller.isWaitingContacts, isTrue);
    expect(controller.isLoadingContacts, isFalse);
    expect(controller.hasVisibleContacts, isFalse);

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: L10n.localizationsDelegates,
        supportedLocales: L10n.supportedLocales,
        home: Scaffold(
          body: CustomScrollView(
            slivers: [
              SliverLoadingContacts(controller: controller),
              SliverEmptyContacts(controller: controller),
            ],
          ),
        ),
      ),
    );

    expect(find.byType(LoadingContactWidget), findsNothing);
    expect(find.byType(NoContactsFound), findsOneWidget);
  });

  test('contact retry absorbs setup errors', () async {
    final client = MockClient();
    when(client.userID).thenReturn('@alice:example.org');
    contactsManager.cancelSubscriptionsError = StateError(
      'subscription cancellation failed',
    );

    await expectLater(
      controller.retrySynchronizeContactsOnContactTab(
        context: MockBuildContext(),
        client: client,
        matrixLocalizations: MockMatrixLocalizations(),
      ),
      completes,
    );
    expect(contactsManager.cancelSubscriptionsCalled, isTrue);
  });
}
