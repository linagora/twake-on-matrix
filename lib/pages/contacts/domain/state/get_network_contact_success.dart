import 'package:fluffychat/entity/contact/contact.dart';
import 'package:fluffychat/pages/contacts/presentation/model/presentation_contact.dart';
import 'package:fluffychat/pages/contacts/domain/state/get_contacts_success.dart';

class GetNetworkContactSuccess extends GetContactsSuccess {
  const GetNetworkContactSuccess({
    required Set<Contact> contacts
  }) : super(contacts: contacts);
}