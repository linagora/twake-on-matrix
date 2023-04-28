import 'package:fluffychat/entity/contact/contact.dart';
import 'package:fluffychat/pages/contacts/domain/state/get_contacts_success.dart';

class GetLocalContactSuccess extends GetContactsSuccess {
  const GetLocalContactSuccess({
    required Set<Contact> contacts
  }) : super(contacts: contacts);
}