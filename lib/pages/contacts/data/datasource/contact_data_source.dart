import 'package:fluffychat/entity/contact/contact.dart';

abstract class ContactDataSource {
  Future<Set<Contact>> getContacts();
}

enum LocalDataSourceType {
  device,
}

enum NetworkDataSourceType {
  tomclient,
}