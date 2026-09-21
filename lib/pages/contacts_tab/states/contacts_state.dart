import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:twake_chat/domain/contact/entities/unified_contact.dart';

part 'contacts_state.freezed.dart';

/// UI projection of the unified contact store.
///
/// It combines the store stream ([contacts]) with the local search keyword,
/// and exposes the filtered list the list widget renders.
@freezed
abstract class ContactsState with _$ContactsState {
  const ContactsState._();

  const factory ContactsState({
    @Default(AsyncLoading<List<UnifiedContact>>())
    AsyncValue<List<UnifiedContact>> contacts,
    @Default('') String keyword,
  }) = _ContactsState;

  bool get isSearching => keyword.trim().isNotEmpty;

  List<UnifiedContact> get allContacts =>
      contacts.asData?.value ?? const <UnifiedContact>[];

  List<UnifiedContact> get visibleContacts {
    final keyword = this.keyword.trim().toLowerCase();
    if (keyword.isEmpty) return allContacts;
    return allContacts
        .where((contact) => _matches(contact, keyword))
        .toList(growable: false);
  }
}

bool _matches(UnifiedContact contact, String keyword) {
  bool contains(String? value) =>
      value != null && value.toLowerCase().contains(keyword);

  return contains(contact.resolvedDisplayName) ||
      contains(contact.matrixId) ||
      contact.emails.any(contains) ||
      contact.phones.any(contains);
}
