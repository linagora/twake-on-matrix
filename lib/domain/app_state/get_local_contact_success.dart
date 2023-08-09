import 'package:fluffychat/domain/app_state/contact/get_contacts_success.dart';
import 'package:fluffychat/domain/model/contact/contact.dart';

class GetLocalContactSuccess extends GetContactsSuccess {
  const GetLocalContactSuccess({
    required Set<Contact> contacts,
  }) : super(contacts: contacts);
}
