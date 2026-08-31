import 'dart:async';

import 'package:twake_chat/di/global/get_it_initializer.dart';
import 'package:twake_chat/domain/model/extensions/homeserver_summary_extensions.dart';
import 'package:twake_chat/presentation/mixins/address_book_mixin.dart';
import 'package:twake_chat/presentation/mixins/comparable_presentation_contact_mixin.dart';
import 'package:twake_chat/pages/contacts_tab/contacts_tab_view.dart';
import 'package:twake_chat/presentation/mixins/contacts_view_controller_mixin.dart';
import 'package:twake_chat/presentation/model/contact/presentation_contact.dart';
import 'package:twake_chat/presentation/model/contact/presentation_contact_constant.dart';
import 'package:twake_chat/providers/login_homeserver_summary_provider.dart';
import 'package:twake_chat/utils/matrix_sdk_extensions/matrix_locals.dart';
import 'package:twake_chat/utils/responsive/responsive_utils.dart';
import 'package:twake_chat/utils/string_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:twake_chat/widgets/matrix.dart';
import 'package:twake_chat/config/go_routes/app_routes.dart';
import 'package:go_router/go_router.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:matrix/matrix.dart';

class ContactsTab extends ConsumerStatefulWidget {
  final Widget? bottomNavigationBar;

  const ContactsTab({super.key, this.bottomNavigationBar});

  @override
  ConsumerState<ContactsTab> createState() => ContactsTabController();
}

class ContactsTabController extends ConsumerState<ContactsTab>
    with
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
  bool get isInvitationEnabled =>
      mounted && ref.read(loginHomeserverSummaryProvider).isInvitationEnabled;

  @override
  void initState() {
    // The well-known can land after the first synchronization skipped the
    // phonebook.
    ref.listenManual(
      loginHomeserverSummaryProvider.select(
        (summary) => summary.isInvitationEnabled,
      ),
      (previous, next) {
        if (next) {
          unawaited(retrySynchronizeContacts());
        }
      },
    );
    SchedulerBinding.instance.addPostFrameCallback((_) async {
      WidgetsBinding.instance.addObserver(this);
      if (mounted) {
        listenAddressBookEvents(client);
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
