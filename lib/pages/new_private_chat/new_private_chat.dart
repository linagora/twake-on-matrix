import 'package:twake_chat/domain/model/extensions/homeserver_summary_extensions.dart';
import 'package:twake_chat/presentation/mixins/address_book_mixin.dart';
import 'package:twake_chat/presentation/mixins/comparable_presentation_contact_mixin.dart';
import 'package:twake_chat/presentation/mixins/contacts_view_controller_mixin.dart';
import 'package:twake_chat/presentation/mixins/go_to_group_chat_mixin.dart';
import 'package:twake_chat/presentation/mixins/invite_external_contact_mixin.dart';
import 'package:twake_chat/pages/new_private_chat/new_private_chat_view.dart';
import 'package:twake_chat/presentation/mixins/go_to_direct_chat_mixin.dart';
import 'package:twake_chat/presentation/model/contact/presentation_contact.dart';
import 'package:twake_chat/presentation/model/search/presentation_search.dart';
import 'package:twake_chat/providers/login_homeserver_summary_provider.dart';
import 'package:twake_chat/utils/matrix_sdk_extensions/matrix_locals.dart';
import 'package:twake_chat/widgets/matrix.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:twake_chat/config/go_routes/app_routes.dart';
import 'package:matrix/matrix.dart';

class NewPrivateChat extends ConsumerStatefulWidget {
  const NewPrivateChat({super.key});

  @override
  NewPrivateChatController createState() => NewPrivateChatController();
}

class NewPrivateChatController extends ConsumerState<NewPrivateChat>
    with
        ComparablePresentationContactMixin,
        ContactsViewControllerMixin,
        GoToDraftChatMixin,
        WidgetsBindingObserver,
        InviteExternalContactMixin,
        AddressBooksMixin,
        GoToGroupChatMixin {
  final scrollController = ScrollController();

  ProviderSubscription<bool>? _invitationEnabledSubscription;

  @override
  bool get isInvitationEnabled =>
      mounted && ref.read(loginHomeserverSummaryProvider).isInvitationEnabled;

  @override
  void initState() {
    super.initState();
    // The well-known can land after contacts without a Matrix ID were hidden.
    _invitationEnabledSubscription = ref.listenManual(
      loginHomeserverSummaryProvider.select(
        (summary) => summary.isInvitationEnabled,
      ),
      (_, _) => refreshAllContacts(
        context: context,
        client: Matrix.of(context).client,
        matrixLocalizations: MatrixLocals(L10n.of(context)!),
      ),
    );
    SchedulerBinding.instance.addPostFrameCallback((_) async {
      WidgetsBinding.instance.addObserver(this);
      if (mounted) {
        final client = Matrix.of(context).client;
        listenAddressBookEvents(client);
        initialFetchContacts(
          context: context,
          client: client,
          matrixLocalizations: MatrixLocals(L10n.of(context)!),
        );
      }
    });
    // FIXME: Find out solution for disable load more in search
    // searchContactsController.onSearchKeywordChanged = (searchKey) {
    //   disableLoadMoreInSearch();
    // };
  }

  void onContactAction(
    BuildContext context,
    PresentationContact contact,
  ) async {
    if (contact.matrixId == null || contact.matrixId?.isEmpty == true) {
      Logs().e('NewPrivateChatController::onContactAction: no MatrixId');
      return;
    }
    final roomId = Matrix.of(
      context,
    ).client.getDirectChatFromUserId(contact.matrixId!);
    final room = roomId != null
        ? Matrix.of(context).client.getRoomById(roomId)
        : null;
    if (roomId == null || room?.isAbandonedDMRoom == true) {
      goToDraftChat(
        context: context,
        path: 'rooms',
        contactPresentationSearch: ContactPresentationSearch(
          matrixId: contact.matrixId,
          displayName: contact.displayName,
        ),
      );
    } else {
      RoomRoute(roomid: roomId).push(context);
    }
  }

  void onExternalContactAction(
    BuildContext context,
    PresentationContact contact,
  ) {
    showInviteExternalContactDialog(context, () {
      onContactAction(context, contact);
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    await handleDidChangeAppLifecycleState(
      state,
      client: Matrix.of(context).client,
    );
  }

  @override
  void dispose() {
    _invitationEnabledSubscription?.close();
    WidgetsBinding.instance.removeObserver(this);
    disposeContactsMixin();
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => NewPrivateChatView(this);
}
