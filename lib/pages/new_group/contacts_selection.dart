import 'package:twake_chat/domain/model/extensions/homeserver_summary_extensions.dart';
import 'package:twake_chat/presentation/mixins/address_book_mixin.dart';
import 'package:twake_chat/presentation/mixins/contacts_view_controller_mixin.dart';
import 'package:twake_chat/presentation/mixins/invite_external_contact_mixin.dart';
import 'package:twake_chat/pages/new_group/contacts_selection_view.dart';
import 'package:twake_chat/pages/new_group/selected_contacts_map_change_notifier.dart';
import 'package:twake_chat/presentation/model/contact/presentation_contact.dart';
import 'package:twake_chat/utils/matrix_sdk_extensions/matrix_locals.dart';
import 'package:twake_chat/widgets/matrix.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:matrix/matrix.dart';

abstract class ContactsSelectionController<T extends StatefulWidget>
    extends State<T>
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

  @override
  bool get isInvitationEnabled =>
      mounted && Matrix.of(context).loginHomeserverSummary.isInvitationEnabled;

  Client get client => Matrix.of(context).client;

  @override
  void initState() {
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
    super.initState();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    await handleDidChangeAppLifecycleState(state, client: client);
  }

  @override
  void dispose() {
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
