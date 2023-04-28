import 'package:fluffychat/domain/model/contact/contact.dart';
import 'package:fluffychat/domain/state/contact/get_contacts_success.dart';

class GetLocalContactSuccess extends GetContactsSuccess {
  const GetLocalContactSuccess({
    required Set<Contact> contacts
  }) : super(contacts: contacts);
}