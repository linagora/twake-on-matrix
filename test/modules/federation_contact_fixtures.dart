import 'package:fluffychat/modules/federation_identity_lookup/domain/models/federation_contact.dart';
import 'package:fluffychat/modules/federation_identity_lookup/domain/models/federation_third_party_contact.dart';

class FederationContactFixtures {
  static FederationContact contact1 = FederationContact(
    id: 'id_1',
    name: 'Alice',
    phoneNumbers: {FederationPhone(number: '(212)555-6789')},
    emails: {FederationEmail(address: 'alice@gmail.com')},
  );

  static FederationContact contact2 = FederationContact(
    id: 'id_2',
    name: 'Bob',
    phoneNumbers: {FederationPhone(number: '(212)555-1234')},
    emails: {FederationEmail(address: 'bob@gmail.com')},
  );

  static FederationContact contact3 = FederationContact(
    id: 'id_3',
    name: 'Charlie',
    phoneNumbers: {FederationPhone(number: '(212)555-2345')},
  );

  static FederationContact contact4 = FederationContact(
    id: 'id_4',
    name: 'Diana',
    emails: {FederationEmail(address: 'diana@gmail.com')},
  );

  static FederationContact contact5 = FederationContact(
    id: 'id_5',
    name: 'Eve',
    phoneNumbers: {FederationPhone(number: '(212)555-4567')},
  );

  static FederationContact contact6 = FederationContact(
    id: 'id_6',
    name: 'Frank',
    emails: {FederationEmail(address: 'frank@gmail.com')},
  );
}
