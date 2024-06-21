import 'package:fluffychat/data/datasource/tom_contacts_datasource.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/domain/model/contact/contact.dart';
import 'package:fluffychat/domain/model/contact/contact_query.dart';
import 'package:fluffychat/domain/model/contact/lookup_mxid_request.dart';
import 'package:fluffychat/domain/repository/contact_repository.dart';

class TomContactRepositoryImpl implements ContactRepository {
  final TomContactsDatasource datasource = getIt.get<TomContactsDatasource>();

  TomContactRepositoryImpl();

  @override
  Future<List<Contact>> fetchContacts({
    required ContactQuery query,
    int? limit,
    int? offset,
  }) async {
    return datasource.fetchContacts(
      query: query,
      limit: limit,
      offset: offset,
    );
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
