import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/presentation/mixins/comparable_presentation_contact_mixin.dart';
import 'package:fluffychat/pages/contacts_tab/contacts_tab_view.dart';
import 'package:fluffychat/presentation/mixins/contacts_view_controller_mixin.dart';
import 'package:fluffychat/presentation/model/contact/presentation_contact.dart';
import 'package:fluffychat/presentation/model/contact/presentation_contact_constant.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions/matrix_locals.dart';
import 'package:fluffychat/utils/responsive/responsive_utils.dart';
import 'package:fluffychat/utils/string_extension.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:fluffychat/widgets/matrix.dart';
import 'package:flutter/cupertino.dart';
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
    with ComparablePresentationContactMixin, ContactsViewControllerMixin {
  final responsive = getIt.get<ResponsiveUtils>();

  @override
  void initState() {
    SchedulerBinding.instance.addPostFrameCallback((_) async {
      if (mounted) {
        initialFetchContacts(
          client: Matrix.of(context).client,
          matrixLocalizations: MatrixLocals(L10n.of(context)!),
        );
      }
    });

    _listenFocusTextEditing();
    super.initState();
  }

  void _listenFocusTextEditing() {
    searchFocusNode.addListener(() {
      isSearchModeNotifier.value = searchFocusNode.hasFocus;
    });
  }

  void onContactTap({
    required BuildContext context,
    required String path,
    required PresentationContact contact,
  }) {
    if (contact.matrixId?.isCurrentMatrixId(context) == true) {
      goToSettingsProfile();
      return;
    }
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

  void goToSettingsProfile() {
    context.go('/rooms/profile');
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
    disposeContactsMixin();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ContactsTabView(
        contactsController: this,
        bottomNavigationBar: widget.bottomNavigationBar,
      );
}
