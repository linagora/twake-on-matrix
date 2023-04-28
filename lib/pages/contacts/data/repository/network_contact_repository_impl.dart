import 'package:fluffychat/entity/contact/contact.dart';
import 'package:fluffychat/pages/contacts/data/datasource/contact_data_source.dart';
import 'package:fluffychat/pages/contacts/domain/repository/network_contact_repository.dart';

class NetworkContactRepositoryImpl implements NetworkContactRepository {
  final Map<NetworkDataSourceType, ContactDataSource> datasources;

  NetworkContactRepositoryImpl({required this.datasources});

  @override
  Future<Set<Contact>> getContacts() async {
    return await datasources[NetworkDataSourceType.tomclient]
      !.getContacts();
  }
  
}