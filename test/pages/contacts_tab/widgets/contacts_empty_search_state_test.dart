import 'package:dartz/dartz.dart';
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/domain/app_state/contact/get_contacts_state.dart';
import 'package:fluffychat/domain/app_state/contact/get_phonebook_contact_state.dart';
import 'package:fluffychat/generated/l10n/app_localizations.dart';
import 'package:fluffychat/pages/contacts_tab/contacts_tab.dart';
import 'package:fluffychat/pages/contacts_tab/widgets/sliver_empty_contacts.dart';
import 'package:fluffychat/pages/contacts_tab/widgets/sliver_loading_contacts.dart';
import 'package:fluffychat/pages/new_private_chat/widget/loading_contact_widget.dart';
import 'package:fluffychat/pages/new_private_chat/widget/no_contacts_found.dart';
import 'package:fluffychat/presentation/extensions/value_notifier_custom.dart';
import 'package:fluffychat/presentation/model/search/presentation_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'contacts_empty_search_state_test.mocks.dart';

@GenerateNiceMocks([MockSpec<ContactsTabController>()])
void main() {
  testWidgets(
    'shows the empty search state when the phonebook remains initial',
    (tester) async {
      final controller = MockContactsTabController();
      final contactNotifier = ValueNotifierCustom<Either<Failure, Success>>(
        const Right(ContactsInitial()),
      );
      final phonebookNotifier = ValueNotifierCustom<Either<Failure, Success>>(
        const Right(GetPhonebookContactsInitial()),
      );
      final recentContactNotifier =
          ValueNotifierCustom<List<PresentationSearch>>([]);
      final textEditingController = TextEditingController(text: 'missing');

      addTearDown(contactNotifier.dispose);
      addTearDown(phonebookNotifier.dispose);
      addTearDown(recentContactNotifier.dispose);
      addTearDown(textEditingController.dispose);

      when(controller.presentationContactNotifier).thenReturn(contactNotifier);
      when(
        controller.presentationPhonebookContactNotifier,
      ).thenReturn(phonebookNotifier);
      when(
        controller.presentationRecentContactNotifier,
      ).thenReturn(recentContactNotifier);
      when(controller.isWaitingContacts).thenReturn(true);
      when(controller.isLoadingContacts).thenReturn(false);
      when(controller.hasVisibleContacts).thenReturn(false);
      when(controller.textEditingController).thenReturn(textEditingController);

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
    },
  );
}
