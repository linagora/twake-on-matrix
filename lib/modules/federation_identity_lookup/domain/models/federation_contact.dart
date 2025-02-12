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

  @override
  List<Object?> get props => [
        id,
        phoneNumbers,
        emails,
      ];

  FederationContact copyWith({
    Set<FederationPhone>? phoneNumbers,
    Set<FederationEmail>? emails,
  }) {
    return FederationContact(
      id: id,
      phoneNumbers: phoneNumbers ?? this.phoneNumbers,
      emails: emails ?? this.emails,
    );
  }
}
