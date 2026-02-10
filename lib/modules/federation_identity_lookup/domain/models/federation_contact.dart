import 'package:equatable/equatable.dart';
import 'package:fluffychat/modules/federation_identity_lookup/domain/models/federation_third_party_contact.dart';

class FederationContact with EquatableMixin {
  final String id;

  final String name;

  final Set<FederationPhone>? phoneNumbers;

  final Set<FederationEmail>? emails;

  FederationContact({
    required this.id,
    required this.name,
    this.phoneNumbers,
    this.emails,
  });

  @override
  List<Object?> get props => [id, name, phoneNumbers, emails];

  FederationContact copyWith({
    Set<FederationPhone>? phoneNumbers,
    Set<FederationEmail>? emails,
  }) {
    return FederationContact(
      id: id,
      name: name,
      phoneNumbers: phoneNumbers ?? this.phoneNumbers,
      emails: emails ?? this.emails,
    );
  }
}
