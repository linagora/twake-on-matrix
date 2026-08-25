import 'package:twake_chat/data/datasource/tom_contacts_datasource.dart';
import 'package:twake_chat/data/network/contact/tom_contact_api.dart';
import 'package:twake_chat/di/global/get_it_initializer.dart';
import 'package:twake_chat/domain/model/contact/contact.dart';
import 'package:twake_chat/domain/model/contact/contact_query.dart';
import 'package:twake_chat/domain/model/contact/contact_status.dart';
import 'package:twake_chat/domain/model/contact/lookup_mxid_request.dart';
import 'package:twake_chat/domain/model/extensions/contact/tom_contact_extension.dart';

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
        .removeUnknownTomContact()
        .map((contact) => contact.toContact(ContactStatus.active))
        .toList();

    contacts.addAll(
      response.inactiveContacts.removeUnknownTomContact().map(
        (contact) => contact.toContact(ContactStatus.inactive),
      ),
    );

    return contacts;
  }
}
