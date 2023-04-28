import 'package:fluffychat/domain/model/contact/contact.dart';
import 'package:fluffychat/pages/contacts/data/datasource/contact_data_source.dart';
import 'package:fluffychat/pages/contacts/data/datasource/device_contact_data_source.dart';
import 'package:fluffychat/pages/contacts/domain/repository/local_contact_repository.dart';

// class LocalContactRepositoryImpl implements LocalContactRepository {
//   final Map<LocalDataSourceType, DeviceContactDataSource> datasources;

//   LocalContactRepositoryImpl({required this.datasources});

//   @override
//   Future<Set<Contact>> getContacts({withThumbnail = false}) async {
//     return await datasources[LocalDataSourceType.device]
//       !.getContacts(withThumbnail: withThumbnail);
//   }
// }