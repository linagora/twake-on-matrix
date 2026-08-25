import 'package:twake_chat/data/datasource/tom_contacts_datasource.dart';
import 'package:twake_chat/di/global/get_it_initializer.dart';
import 'package:twake_chat/domain/model/contact/contact.dart';
import 'package:twake_chat/domain/model/contact/contact_query.dart';
import 'package:twake_chat/domain/model/contact/lookup_mxid_request.dart';
import 'package:twake_chat/domain/repository/contact_repository.dart';

class TomContactRepositoryImpl implements ContactRepository {
  final TomContactsDatasource datasource = getIt.get<TomContactsDatasource>();

  TomContactRepositoryImpl();

  @override
  Future<List<Contact>> fetchContacts({
    required ContactQuery query,
    int? limit,
    int? offset,
  }) async {
    return datasource.fetchContacts(query: query, limit: limit, offset: offset);
  }

  @override
  Future<List<Contact>> lookupMatchContact({
    required ContactQuery query,
    LookupMxidRequest? lookupMxidRequest,
  }) async {
    return datasource.fetchContacts(
      query: query,
      lookupMxidRequest: lookupMxidRequest,
    );
  }
}
