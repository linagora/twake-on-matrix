import 'package:twake_chat/data/datasource/contact/phonebook_datasource.dart';
import 'package:twake_chat/di/global/get_it_initializer.dart';
import 'package:twake_chat/domain/model/contact/contact.dart';
import 'package:twake_chat/domain/repository/phonebook_contact_repository.dart';

class PhonebookContactRepositoryImpl extends PhonebookContactRepository {
  final PhonebookContactDatasource datasource = getIt
      .get<PhonebookContactDatasource>();

  @override
  Future<List<Contact>> fetchContacts() {
    return datasource.fetchContacts();
  }
}
