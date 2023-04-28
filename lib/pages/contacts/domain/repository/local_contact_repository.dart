import 'package:fluffychat/entity/contact/contact.dart';
import 'package:fluffychat/pages/contacts/domain/repository/contact_repository.dart';

abstract class LocalContactRepository extends ContactRepository {
  @override
  Future<Set<Contact>> getContacts({withThumbnail = false});
}