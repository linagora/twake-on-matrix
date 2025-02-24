import 'package:fluffychat/modules/federation_identity_lookup/domain/models/federation_hash_details_response.dart';
import 'package:fluffychat/modules/federation_identity_lookup/domain/models/federation_third_party_contact.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Calculate hash using all Peppers test', () {
    test(
      'Given a hash details response with no algorithms'
      'When calculateHashUsingAllPeppers is called'
      'Then an empty set is returned',
      () {
        const hashDetails = FederationHashDetailsResponse(
          algorithms: null,
          lookupPepper: 'pepper',
        );

        final result = FederationPhone(
          number: '123456789',
        ).calculateHashUsingAllPeppers(hashDetails: hashDetails);

        expect(result, <String>{});
      },
    );

    test(
      'Given a hash details response with 1 algorithm and 1 pepper'
      'When calculateHashUsingAllPeppers is called'
      'Then a set with 1 hash is returned',
      () {
        const hashDetails = FederationHashDetailsResponse(
          algorithms: {'sha256'},
          lookupPepper: 'pepper',
        );

        final result = FederationPhone(
          number: '123456789',
        ).calculateHashUsingAllPeppers(hashDetails: hashDetails);

        expect(result.isNotEmpty, true);
      },
    );

    test(
      'Given a hash details response with 2 algorithm and 1 pepper'
      'When calculateHashUsingAllPeppers is called'
      'Then a set with 2 hashes is returned',
      () {
        const hashDetails = FederationHashDetailsResponse(
          algorithms: {
            'sha256',
            'none',
          },
          lookupPepper: 'pepper',
        );

        final result = FederationPhone(
          number: '123456789',
        ).calculateHashUsingAllPeppers(hashDetails: hashDetails);

        expect(result.length, 2);
      },
    );
  });

  group('Calculate hash with algorithm SHA256', () {
    test(
      'Given a phone number and a pepper is empty'
      'When calculateHashWithAlgorithmSha256 is called'
      'Then a hash is returned',
      () {
        const pepper = '';

        final result = FederationPhone(
          number: '123456789',
        ).calculateHashWithAlgorithmSha256(pepper: pepper);

        expect(result.isNotEmpty, true);
      },
    );

    test(
      'Given a phone number and a pepper'
      'When calculateHashWithAlgorithmSha256 is called'
      'Then a hash is returned',
      () {
        const pepper = 'pepper';

        final result = FederationPhone(
          number: '123456789',
        ).calculateHashWithAlgorithmSha256(pepper: pepper);

        expect(result.isNotEmpty, true);
      },
    );
  });
}
