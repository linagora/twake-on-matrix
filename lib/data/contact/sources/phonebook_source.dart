import 'package:twake_chat/data/contact/sources/sourced_contact_mapper.dart';
import 'package:twake_chat/domain/contact/entities/contact_source_kind.dart';
import 'package:twake_chat/domain/contact/sources/contact_source.dart';
import 'package:twake_chat/domain/repository/phonebook_contact_repository.dart';

/// Device phonebook source. Only resolved contacts (with a Matrix ID) are
/// returned; the user's local name is exposed as [ContactSourceKind.phonebook]
/// so the resolution policy can use it as the preferred alias.
class PhonebookSource implements ContactSource {
  const PhonebookSource(this._repository);

  final PhonebookContactRepository _repository;

  @override
  ContactSourceKind get kind => ContactSourceKind.phonebook;

  @override
  Future<List<SourcedContact>> fetch() async {
    final contacts = await _repository.fetchContacts();

    return contacts
        .map((contact) => contactToSourcedContact(contact: contact, kind: kind))
        .whereType<SourcedContact>()
        .toList(growable: false);
  }
}
