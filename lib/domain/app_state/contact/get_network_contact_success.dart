import 'package:fluffychat/domain/model/contact/contact.dart';

import 'get_contacts_success.dart';

class GetNetworkContactSuccess extends GetContactsSuccess {
  const GetNetworkContactSuccess({
    required Set<Contact> contacts,
  }) : super(contacts: contacts);
}

class GetMoreNetworkContactSuccess extends GetContactsSuccess {
  const GetMoreNetworkContactSuccess({
    required Set<Contact> contacts,
    int? limit,
    int? offset,
  }) : super(contacts: contacts);
}

class NoMoreContactSuccess extends GetContactsSuccess {
  const NoMoreContactSuccess({
    required Set<Contact> contacts,
  }) : super(contacts: contacts);
}
