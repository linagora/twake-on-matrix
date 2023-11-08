import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/mixin/comparable_presentation_contact_mixin.dart';
import 'package:fluffychat/pages/contacts_tab/contacts_tab_view.dart';
import 'package:fluffychat/presentation/model/presentation_contact.dart';
import 'package:fluffychat/presentation/model/presentation_contact_constant.dart';
import 'package:fluffychat/utils/responsive/responsive_utils.dart';
import 'package:fluffychat/widgets/matrix.dart';
import 'package:flutter/cupertino.dart';
import 'package:fluffychat/presentation/contact_manager/contact_manager.dart';
import 'package:go_router/go_router.dart';

class ContactsTab extends StatefulWidget {
  final Widget? bottomNavigationBar;

  const ContactsTab({
    super.key,
    this.bottomNavigationBar,
  });

  @override
  State<StatefulWidget> createState() => ContactsTabController();
}

class ContactsTabController extends State<ContactsTab>
    with ComparablePresentationContactMixin {
  final responsive = getIt.get<ResponsiveUtils>();

  final contactManager = getIt.get<ContactManager>();

  @override
  void initState() {
    contactManager.initSearchContacts();
    _listenFocusTextEditing();
    super.initState();
  }

  void _listenFocusTextEditing() {
    contactManager.searchFocusNode.addListener(() {
      contactManager.isSearchModeNotifier.value =
          contactManager.searchFocusNode.hasFocus;
    });
  }

  void onContactTap({
    required BuildContext context,
    required String path,
    required PresentationContact contact,
  }) {
    final roomId =
        Matrix.of(context).client.getDirectChatFromUserId(contact.matrixId!);
    if (roomId == null) {
      goToDraftChat(
        context: context,
        path: path,
        contact: contact,
      );
    } else {
      context.go('/$path/$roomId');
    }
  }

  void goToDraftChat({
    required BuildContext context,
    required String path,
    required PresentationContact contact,
  }) {
    if (contact.matrixId != Matrix.of(context).client.userID) {
      Router.neglect(
        context,
        () => context.go(
          '/$path/draftChat',
          extra: {
            PresentationContactConstant.receiverId: contact.matrixId ?? '',
            PresentationContactConstant.email: contact.email ?? '',
            PresentationContactConstant.displayName: contact.displayName ?? '',
            PresentationContactConstant.status: '',
          },
        ),
      );
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ContactsTabView(
        contactsController: this,
        bottomNavigationBar: widget.bottomNavigationBar,
      );
}
