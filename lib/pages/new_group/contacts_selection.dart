import 'package:fluffychat/domain/model/contact/contact_type.dart';
import 'package:fluffychat/presentation/mixins/contacts_view_controller_mixin.dart';
import 'package:fluffychat/presentation/mixins/invite_external_contact_mixin.dart';
import 'package:fluffychat/pages/new_group/contacts_selection_view.dart';
import 'package:fluffychat/pages/new_group/selected_contacts_map_change_notifier.dart';
import 'package:fluffychat/presentation/model/contact/presentation_contact.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions/matrix_locals.dart';
import 'package:fluffychat/widgets/matrix.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter/cupertino.dart';
import 'package:matrix/matrix.dart';

abstract class ContactsSelectionController<T extends StatefulWidget>
    extends State<T>
    with InviteExternalContactMixin, ContactsViewControllerMixin {
  final selectedContactsMapNotifier = SelectedContactsMapChangeNotifier();

  String getTitle(BuildContext context);

  String getHintText(BuildContext context);

  void onSubmit();

  List<String> get disabledContactIds => [];

  Iterable<PresentationContact> get contactsList =>
      selectedContactsMapNotifier.contactsList;

  bool get isContainsExternal =>
      contactsList.any((contact) => contact.type == ContactType.external);

  bool get isFullScreen => true;

  Client get client => Matrix.of(context).client;

  @override
  void initState() {
    SchedulerBinding.instance.addPostFrameCallback((_) async {
      if (mounted) {
        initialFetchContacts(
          client: client,
          matrixLocalizations: MatrixLocals(L10n.of(context)!),
        );
      }
    });
    super.initState();
  }

  @override
  void dispose() {
    disposeContactsMixin();
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
