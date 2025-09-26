import 'package:fluffychat/presentation/extensions/contact/presentation_contact_extension.dart';
import 'package:fluffychat/presentation/mixins/address_book_mixin.dart';
import 'package:fluffychat/presentation/mixins/contacts_view_controller_mixin.dart';
import 'package:fluffychat/presentation/mixins/invite_external_contact_mixin.dart';
import 'package:fluffychat/pages/new_group/contacts_selection_view.dart';
import 'package:fluffychat/pages/new_group/selected_contacts_map_change_notifier.dart';
import 'package:fluffychat/presentation/model/contact/presentation_contact.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions/matrix_locals.dart';
import 'package:fluffychat/widgets/matrix.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
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

  bool get isContainsExternal =>
      contactsList.any((contact) => contact.isContainsExternal(client));

  bool get isFullScreen => true;

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
    if (isContainsExternal) {
      showInviteExternalContactDialog(context, onSubmit);
    } else {
      onSubmit();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ContactsSelectionView(this);
  }
}
