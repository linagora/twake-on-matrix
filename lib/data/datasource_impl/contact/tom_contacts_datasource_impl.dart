import 'package:fluffychat/data/datasource/tom_contacts_datasource.dart';
import 'package:fluffychat/data/network/contact/tom_contact_api.dart';
import 'package:fluffychat/domain/model/contact/contact.dart';
import 'package:fluffychat/domain/model/contact/contact_query.dart';
import 'package:fluffychat/domain/model/extensions/tom_contact_extension.dart';

class TomContactsDatasourceImpl implements TomContactsDatasource {

  final TomContactAPI tomContactAPI;

  TomContactsDatasourceImpl({
    required this.tomContactAPI,
  });

  @override
  Future<Set<Contact>> searchContacts({required ContactQuery query}) async {
    final response = await tomContactAPI.searchContacts(query);
    return response.contacts.toContact();
  }
  
  @override
  Future<Set<Contact>> fetchContacts() {
    return Future.value({
      Contact(emails: {"quangpro@gmail.com"}, displayName: "Quang Teo", matrixId: "@quangteo:matrix.org"),
      Contact(emails: {"quangprovip@gmail.com"}, displayName: "Quang Mien", matrixId: "@quangmien:matrix.org"),
      Contact(emails: {"quangprovipvip@gmail.com"}, displayName: "Quang Pro vip", matrixId: "@quangprovip:matrix.org"),
      Contact(emails: {"quangchemgio@gmail.com"}, displayName: "Quang Chem Gio", matrixId: "@quangchemgio:matrix.org"),
    });
  }
}