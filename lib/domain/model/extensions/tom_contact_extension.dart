import 'package:fluffychat/domain/model/contact/contact.dart';
import 'package:fluffychat/domain/model/contact/tom_contact.dart';

extension TomContactExtension on Set<TomContact> {
  Set<Contact> toContact() {
    return map<Contact>((contact) => Contact(
        emails: { contact.mail! }, 
        displayName: contact.mxid!,
        phoneNumber: contact.phoneNumber,
        matrixId: contact.mxid!,
      )).toSet();
  }
}