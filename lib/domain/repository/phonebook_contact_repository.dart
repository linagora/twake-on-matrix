import 'package:fluffychat/domain/model/contact/contact.dart';
import 'package:flutter/foundation.dart';

abstract class PhonebookContactRepository {
  Future<List<Contact>> fetchContacts();

  void addListener(VoidCallback callback);

  void removeListener(VoidCallback callback);
}
