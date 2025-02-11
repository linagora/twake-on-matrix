import 'package:equatable/equatable.dart';
import 'package:fluffychat/modules/federation_identity_lookup/domain/models/federation_third_party_contact.dart';

class FederationContact with EquatableMixin {
  final String id;

  final Set<FederationPhone>? phoneNumbers;

  final Set<FederationEmail>? emails;

  FederationContact({
    required this.id,
    this.phoneNumbers,
    this.emails,
  });

  Set<String> calculateHashUsingAllPeppers({
    required String lookupPepper,
    required Set<String> algorithms,
  }) {
    final Set<String> hashes = {};

    if (algorithms.isEmpty) {
      return hashes;
    }

    if (phoneNumbers != null) {
      for (final phoneNumber in phoneNumbers!) {
        final hash = phoneNumber.calculateHashWithAlgorithmSha256(
          pepper: lookupPepper,
        );

        hashes.add(hash);
      }
    }

    if (emails != null) {
      for (final email in emails!) {
        final hash = email.calculateHashWithAlgorithmSha256(
          pepper: lookupPepper,
        );

        hashes.add(hash);
      }
    }

    return hashes;
  }

  @override
  List<Object?> get props => [
        id,
        phoneNumbers,
        emails,
      ];
}
