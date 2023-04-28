import 'package:fluffychat/domain/model/contact/contact.dart';
import 'package:fluffychat/domain/state/contact/get_contacts_success.dart';

class GetNetworkContactSuccess extends GetContactsSuccess {
  const GetNetworkContactSuccess({
    required Set<Contact> contacts
  }) : super(contacts: contacts);
}