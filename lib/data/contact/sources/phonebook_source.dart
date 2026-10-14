import 'package:twake_chat/data/contact/sources/sourced_contact_mapper.dart';
import 'package:twake_chat/domain/contact/entities/contact_source_kind.dart';
import 'package:twake_chat/domain/contact/sources/contact_source.dart';
import 'package:twake_chat/domain/repository/contact/hive_contact_repository.dart';

/// Device phonebook source.
///
/// Only resolved contacts (with a Matrix ID) are returned; the user's local
/// name is exposed as [ContactSourceKind.phonebook] so the resolution policy
/// can use it as the preferred alias.
///
/// The raw device contacts carry no Matrix ID: the association is done by the
/// phonebook lookup, which persists the resolved contacts per account in Hive.
/// This source therefore reads [HiveContactRepository.getThirdPartyContactByUserId]
/// rather than the raw device phonebook.
class PhonebookSource implements ContactSource {
  const PhonebookSource(this._repository);

  final HiveContactRepository _repository;

  @override
  ContactSourceKind get kind => ContactSourceKind.phonebook;

  @override
  Future<List<SourcedContact>> fetch(String userId) async {
    final contacts = await _repository.getThirdPartyContactByUserId(userId);

    return contacts
        .map((contact) => contactToSourcedContact(contact: contact, kind: kind))
        .whereType<SourcedContact>()
        .toList(growable: false);
  }
}
