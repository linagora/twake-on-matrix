import 'package:fluffychat/domain/model/contact/contact.dart';
import 'package:fluffychat/pages/contacts/data/datasource/contact_data_source.dart';

class TomClientDataSource extends ContactDataSource {
  @override
  Future<Set<Contact>> getContacts() {
    return Future.delayed(Duration(seconds: 5), () => {
      Contact(emails: {'qkdo@linagora.com', 'quangkhai@gmail.com', 'qk123@gmail.com'}, displayName: 'Quang Khai'),
      Contact(emails: {'superman@linagora.com'}, displayName: 'bro whatup'),
      Contact(emails: {'supersonic@gmail.com'}, displayName: 'sonic'),
    });
  }
}