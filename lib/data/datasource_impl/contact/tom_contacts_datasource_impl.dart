import 'package:fluffychat/data/datasource/tom_contacts_datasource.dart';
import 'package:fluffychat/data/network/contact/tom_contact_api.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/domain/model/contact/contact.dart';
import 'package:fluffychat/domain/model/contact/contact_query.dart';
import 'package:fluffychat/domain/model/contact/contact_status.dart';
import 'package:fluffychat/domain/model/contact/lookup_mxid_request.dart';
import 'package:fluffychat/domain/model/extensions/contact/tom_contact_extension.dart';

class TomContactsDatasourceImpl implements TomContactsDatasource {
  final TomContactAPI _tomContactAPI = getIt.get<TomContactAPI>();

  @override
  Future<List<Contact>> fetchContacts({
    required ContactQuery query,
    int? limit,
    int? offset,
    LookupMxidRequest? lookupMxidRequest,
  }) async {
    final response = await _tomContactAPI.fetchContacts(
      query,
      limit: limit,
      offset: offset,
      lookupMxidRequest: lookupMxidRequest,
    );

    final contacts = response.contacts
        .map((contact) => contact.toContact(ContactStatus.active))
        .toList();

    contacts.addAll(
      response.inactiveContacts
          .map((contact) => contact.toContact(ContactStatus.inactive)),
    );

    return contacts;
  }
}
