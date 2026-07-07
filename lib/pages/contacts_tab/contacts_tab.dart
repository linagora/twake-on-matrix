import 'dart:async';

import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/presentation/mixins/address_book_mixin.dart';
import 'package:fluffychat/presentation/mixins/comparable_presentation_contact_mixin.dart';
import 'package:fluffychat/pages/contacts_tab/contacts_tab_view.dart';
import 'package:fluffychat/presentation/mixins/contacts_view_controller_mixin.dart';
import 'package:fluffychat/presentation/mixins/wellknown_mixin.dart';
import 'package:fluffychat/presentation/model/contact/presentation_contact.dart';
import 'package:fluffychat/presentation/model/contact/presentation_contact_constant.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions/matrix_locals.dart';
import 'package:fluffychat/utils/responsive/responsive_utils.dart';
import 'package:fluffychat/utils/string_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:fluffychat/widgets/matrix.dart';
import 'package:fluffychat/config/go_routes/app_routes.dart';
import 'package:go_router/go_router.dart';
import 'package:fluffychat/generated/l10n/app_localizations.dart';
import 'package:matrix/matrix.dart';

class ContactsTab extends StatefulWidget {
  final Widget? bottomNavigationBar;

  const ContactsTab({super.key, this.bottomNavigationBar});

  @override
  State<StatefulWidget> createState() => ContactsTabController();
}

class ContactsTabController extends State<ContactsTab>
    with
        WellKnownMixin,
        ComparablePresentationContactMixin,
        ContactsViewControllerMixin,
        AddressBooksMixin,
        WidgetsBindingObserver,
        AutomaticKeepAliveClientMixin {
  final responsive = getIt.get<ResponsiveUtils>();

  Client get client => Matrix.of(context).client;

  /// The Contacts page reflects the ToM Address Book only; DMs found by the
  /// SDK must not be listed here (issue #3097).
  @override
  bool get enableRecentContacts => false;

  @override
  bool get enablePhonebookContacts => supportInvitation();

  @override
  void initState() {
    SchedulerBinding.instance.addPostFrameCallback((_) async {
      WidgetsBinding.instance.addObserver(this);
      if (mounted) {
        listenAddressBookEvents(client);
        discoveryInformationNotifier.value = Matrix.of(
          context,
        ).loginHomeserverSummary?.discoveryInformation;
        if (discoveryInformationNotifier.value == null) {
          unawaited(_loadWellKnownAndRetryContacts());
        }
        synchronizeContactsOnContactTab(
          context: context,
          client: Matrix.of(context).client,
          matrixLocalizations: MatrixLocals(L10n.of(context)!),
        );
      }
    });

    _listenFocusTextEditing();
    super.initState();
  }

  Future<void> _loadWellKnownAndRetryContacts() async {
    await getWellKnownInformation(client);
    if (!mounted || !supportInvitation()) {
      return;
    }

    await retrySynchronizeContactsOnContactTab(
      context: context,
      client: client,
      matrixLocalizations: MatrixLocals(L10n.of(context)!),
    );
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
    if (contact.matrixId == null || contact.matrixId?.isEmpty == true) {
      Logs().e('ContactsTabController::onContactTap: no MatrixId');
      return;
    }

    if (contact.matrixId?.isCurrentMatrixId(context) == true) {
      goToSettingsProfile();
      return;
    }
    final roomId = Matrix.of(
      context,
    ).client.getDirectChatFromUserId(contact.matrixId!);
    final room = roomId != null
        ? Matrix.of(context).client.getRoomById(roomId)
        : null;
    if (roomId == null || room?.isAbandonedDMRoom == true) {
      goToDraftChat(context: context, path: path, contact: contact);
    } else {
      context.go('/$path/$roomId');
    }
  }

  void goToSettingsProfile() {
    const ProfileRoute().go(context);
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
            PresentationContactConstant.displayName: contact.displayName ?? '',
            PresentationContactConstant.status: '',
          },
        ),
      );
    }
  }

  Future<void> retrySynchronizeContacts() async {
    if (!mounted) {
      return;
    }

    await retrySynchronizeContactsOnContactTab(
      context: context,
      client: Matrix.of(context).client,
      matrixLocalizations: MatrixLocals(L10n.of(context)!),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    await handleDidChangeAppLifecycleState(state, client: client);
  }

  @override
  void dispose() {
    disposeContactsMixin();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return ContactsTabView(
      contactsController: this,
      bottomNavigationBar: widget.bottomNavigationBar,
    );
  }
}
