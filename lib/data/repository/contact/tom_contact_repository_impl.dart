import 'package:fluffychat/data/datasource/tom_contacts_datasource.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/domain/model/contact/contact.dart';
import 'package:fluffychat/domain/model/contact/contact_query.dart';
import 'package:fluffychat/domain/model/contact/hash_details_response.dart';
import 'package:fluffychat/domain/model/contact/lookup_list_mxid_request.dart';
import 'package:fluffychat/domain/model/contact/lookup_list_mxid_response.dart';
import 'package:fluffychat/domain/repository/contact_repository.dart';

class TomContactRepositoryImpl implements ContactRepository {
  final TomContactsDatasource datasource = getIt.get<TomContactsDatasource>();

  TomContactRepositoryImpl();

  @override
  Stream<List<Contact>> fetchContacts({
    required ContactQuery query,
    int? limit,
    int? offset,
  }) async* {
    final response = await datasource.fetchContacts(
      query: query,
      limit: limit,
      offset: offset,
    );

    yield response;
  }

  @override
  Future<HashDetailsResponse> getHashDetails() {
    return datasource.getHashDetails();
  }

  @override
  Future<LookupListMxidResponse> lookupListMxid(LookupListMxidRequest request) {
    return datasource.lookupListMxid(request);
  }
}
