import 'package:fluffychat/domain/model/contact/contact.dart';
import 'package:fluffychat/domain/model/contact/contact_query.dart';

abstract class ContactRepository {
  Future<List<Contact>> searchContact({required ContactQuery query});
}