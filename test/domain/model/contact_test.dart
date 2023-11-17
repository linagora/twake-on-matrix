import 'package:flutter_test/flutter_test.dart';
import 'package:fluffychat/domain/model/contact/contact.dart';
import 'package:fluffychat/domain/model/contact/hash_details_response.dart';

void main() {
  group('calLookupAddress for email', () {
    const contactWithEmail = Contact(
      email: 'alice@example.com',
    );
    test('calLookupAddress no algorithm', () {
      const hashDetails = HashDetailsResponse(
        lookupPepper: 'matrixrocks',
      );
      expect(
        contactWithEmail.calLookupAddress(hashDetails: hashDetails),
        '4kenr7N9drpCJ4AfalmlGQVsOn3o2RHjkADUpXJWZUc',
      );
    });

    test('calLookupAddress no pepper', () {
      const hashDetails = HashDetailsResponse(
        algorithms: {'sha256'},
      );
      expect(
        contactWithEmail.calLookupAddress(hashDetails: hashDetails),
        'VcXk6XdYWm8SS3XJlWr9fg_RA347SJPO7zkenhzr4wY',
      );
    });

    test('calLookupAddress algorithm was not supported', () {
      const hashDetails = HashDetailsResponse(
        algorithms: {'sha1'},
        lookupPepper: 'matrixrocks',
      );
      expect(
        contactWithEmail.calLookupAddress(hashDetails: hashDetails),
        'alice@example.com email',
      );
    });

    test('calLookupAddress sha256 email alice@example.com', () {
      const hashDetails = HashDetailsResponse(
        algorithms: {'sha256'},
        lookupPepper: 'matrixrocks',
      );
      expect(
        contactWithEmail.calLookupAddress(hashDetails: hashDetails),
        '4kenr7N9drpCJ4AfalmlGQVsOn3o2RHjkADUpXJWZUc',
      );
    });

    test('calLookupAddress sha256 email bob@example.com', () {
      const hashDetails = HashDetailsResponse(
        algorithms: {'sha256'},
        lookupPepper: 'matrixrocks',
      );
      const contactWithEmail = Contact(
        email: 'bob@example.com',
      );
      expect(
        contactWithEmail.calLookupAddress(hashDetails: hashDetails),
        'LJwSazmv46n0hlMlsb_iYxI0_HXEqy_yj6Jm636cdT8',
      );
    });
  });

  group('calLookupAddress for phone', () {
    const contactWithPhone = Contact(
      phoneNumber: '18005552067',
    );
    test('calLookupAddress no algorithm', () {
      const hashDetails = HashDetailsResponse(
        lookupPepper: 'matrixrocks',
      );
      expect(
        contactWithPhone.calLookupAddress(hashDetails: hashDetails),
        'nlo35_T5fzSGZzJApqu8lgIudJvmOQtDaHtr-I4rU7I',
      );
    });

    test('calLookupAddress no pepper', () {
      const hashDetails = HashDetailsResponse(
        algorithms: {'sha256'},
      );
      expect(
        contactWithPhone.calLookupAddress(hashDetails: hashDetails),
        'yhfhL7hoq_90UyleXWt95poa0T5fzm-zy_quOHRGh9k',
      );
    });

    test('calLookupAddress algorithm was not supported', () {
      const hashDetails = HashDetailsResponse(
        algorithms: {'sha1'},
        lookupPepper: 'matrixrocks',
      );
      expect(
        contactWithPhone.calLookupAddress(hashDetails: hashDetails),
        '18005552067 msisdn',
      );
    });

    test('calLookupAddress sha256 phone happy case', () {
      const hashDetails = HashDetailsResponse(
        algorithms: {'sha256'},
        lookupPepper: 'matrixrocks',
      );
      expect(
        contactWithPhone.calLookupAddress(hashDetails: hashDetails),
        'nlo35_T5fzSGZzJApqu8lgIudJvmOQtDaHtr-I4rU7I',
      );
    });

    test('calLookupAddress sha256 phone with plus', () {
      const contactWithPhone = Contact(
        phoneNumber: '+84359871995',
      );
      const hashDetails = HashDetailsResponse(
        algorithms: {'sha256'},
        lookupPepper: 'matrixrocks',
      );
      expect(
        contactWithPhone.calLookupAddress(hashDetails: hashDetails),
        'rfWphd04cS7QDkOFPYdufi4ZCJiQnn4ZND3KQ4WDQD8',
      );
    });

    test('calLookupAddress sha256 phone with space', () {
      const contactWithPhone = Contact(
        phoneNumber: '+84 35 987 1995',
      );
      const hashDetails = HashDetailsResponse(
        algorithms: {'sha256'},
        lookupPepper: 'matrixrocks',
      );
      expect(
        contactWithPhone.calLookupAddress(hashDetails: hashDetails),
        'rfWphd04cS7QDkOFPYdufi4ZCJiQnn4ZND3KQ4WDQD8',
      );
    });

    test('calLookupAddress sha256 phone with brace', () {
      const contactWithPhone = Contact(
        phoneNumber: '(+84) 35 987 1995',
      );
      const hashDetails = HashDetailsResponse(
        algorithms: {'sha256'},
        lookupPepper: 'matrixrocks',
      );
      expect(
        contactWithPhone.calLookupAddress(hashDetails: hashDetails),
        'rfWphd04cS7QDkOFPYdufi4ZCJiQnn4ZND3KQ4WDQD8',
      );
    });
  });
}
