import 'package:fluffychat/entity/contact/contact.dart';
import 'package:flutter_contacts/flutter_contacts.dart' as device_contacts;
import 'package:fluffychat/pages/contacts/data/datasource/contact_data_source.dart';


class DeviceContactDataSource implements ContactDataSource {
  
  @override
  Future<Set<Contact>> getContacts({withThumbnail = false}) async {
    final contacts = await device_contacts.FlutterContacts
      .getContacts(withThumbnail: withThumbnail, withProperties: true);
    
    final Set<Contact> results = {};
    for (final deviceContact in contacts) {
      results.add(
        Contact(
          emails: deviceContact.emails
            .map((e) => e.address)
            .toSet(), 
          displayName: deviceContact.displayName,),);
    }
    return results;
  }
}