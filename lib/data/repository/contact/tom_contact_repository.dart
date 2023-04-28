import 'package:fluffychat/data/datasource/tom_contacts_datasource.dart';
import 'package:fluffychat/domain/model/contact/contact.dart';
import 'package:fluffychat/domain/model/contact/contact_query.dart';
import 'package:fluffychat/domain/repository/contact_repository.dart';

class TomContactRepositoryImpl implements ContactRepository {

  final TomContactsDatasource datasource;

  TomContactRepositoryImpl({required this.datasource});

  @override
  Future<Set<Contact>> searchContact({required ContactQuery query}) {
    return datasource.searchContacts(query: query);
  }
  
  @override
  Future<Set<Contact>> fetchContacts() {
    return datasource.fetchContacts();
  }
  
}