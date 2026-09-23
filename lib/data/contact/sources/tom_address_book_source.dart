import 'package:twake_chat/data/contact/sources/sourced_contact_mapper.dart';
import 'package:twake_chat/domain/contact/entities/contact_source_kind.dart';
import 'package:twake_chat/domain/contact/sources/contact_source.dart';
import 'package:twake_chat/domain/model/extensions/contact/address_book_extension.dart';
import 'package:twake_chat/domain/repository/contact/address_book_repository.dart';

/// TOM AddressBook source (`GET /_twake/addressbook`).
///
/// The server already merges User Registry + Synced Address Book (ADR 0029),
/// so this source returns the organisational contacts as-is.
class TomAddressBookSource implements ContactSource {
  const TomAddressBookSource(this._repository);

  final AddressBookRepository _repository;

  @override
  ContactSourceKind get kind => ContactSourceKind.tomAddressBook;

  @override
  Future<List<SourcedContact>> fetch() async {
    final response = await _repository.getAddressBook();
    final contacts = response.addressBooks?.toContacts() ?? const [];

    return contacts
        .map((contact) => contactToSourcedContact(contact: contact, kind: kind))
        .whereType<SourcedContact>()
        .toList(growable: false);
  }
}
