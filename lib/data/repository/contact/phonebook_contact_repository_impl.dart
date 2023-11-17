import 'package:fluffychat/data/datasource/phonebook_datasouce.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/domain/model/contact/contact.dart';
import 'package:fluffychat/domain/repository/phonebook_contact_repository.dart';

class PhonebookContactRepositoryImpl extends PhonebookContactRepository {
  final PhonebookContactDatasource datasource =
      getIt.get<PhonebookContactDatasource>();

  @override
  Future<List<Contact>> fetchContacts() {
    return datasource.fetchContacts();
  }
}
