import 'package:fluffychat/domain/model/contact/contact.dart';
import 'package:flutter/foundation.dart';

abstract class PhonebookContactDatasource {
  Future<List<Contact>> fetchContacts();

  void addListener(VoidCallback callback);

  void removeListener(VoidCallback callback);
}
