import 'package:twake_chat/domain/model/extensions/homeserver_summary_extensions.dart';
import 'package:twake_chat/presentation/mixins/address_book_mixin.dart';
import 'package:twake_chat/presentation/mixins/contacts_view_controller_mixin.dart';
import 'package:twake_chat/presentation/mixins/invite_external_contact_mixin.dart';
import 'package:twake_chat/pages/new_group/contacts_selection_view.dart';
import 'package:twake_chat/pages/new_group/selected_contacts_map_change_notifier.dart';
import 'package:twake_chat/presentation/model/contact/presentation_contact.dart';
import 'package:twake_chat/providers/login_homeserver_summary_provider.dart';
import 'package:twake_chat/utils/matrix_sdk_extensions/matrix_locals.dart';
import 'package:twake_chat/widgets/matrix.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:matrix/matrix.dart';

abstract class ContactsSelectionController<T extends ConsumerStatefulWidget>
    extends ConsumerState<T>
    with
        InviteExternalContactMixin,
        ContactsViewControllerMixin,
        AddressBooksMixin,
        WidgetsBindingObserver {
  final selectedContactsMapNotifier = SelectedContactsMapChangeNotifier();

  String getTitle(BuildContext context);

  String getHintText(BuildContext context);

  void onSubmit();

  List<String> get disabledContactIds => [];

  Iterable<PresentationContact> get contactsList =>
      selectedContactsMapNotifier.contactsList;

  bool get isFullScreen => true;

  ProviderSubscription<bool>? _invitationEnabledSubscription;

  @override
  bool get isInvitationEnabled =>
      mounted && ref.read(loginHomeserverSummaryProvider).isInvitationEnabled;

  Client get client => Matrix.of(context).client;

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
        client: client,
        matrixLocalizations: MatrixLocals(L10n.of(context)!),
      ),
    );
    SchedulerBinding.instance.addPostFrameCallback((_) async {
      WidgetsBinding.instance.addObserver(this);
      if (mounted) {
        listenAddressBookEvents(client);
        initialFetchContacts(
          context: context,
          client: client,
          matrixLocalizations: MatrixLocals(L10n.of(context)!),
        );
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    await handleDidChangeAppLifecycleState(
      state,
      context: context,
      client: client,
    );
  }

  @override
  void dispose() {
    _invitationEnabledSubscription?.close();
    WidgetsBinding.instance.removeObserver(this);
    disposeContactsMixin();
    selectedContactsMapNotifier.dispose();
    super.dispose();
  }

  void trySubmit(BuildContext context) {
    onSubmit();
  }

  @override
  Widget build(BuildContext context) {
    return ContactsSelectionView(this);
  }
}
