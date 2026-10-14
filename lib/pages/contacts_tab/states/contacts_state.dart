import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:twake_chat/domain/contact/entities/unified_contact.dart';
import 'package:twake_chat/presentation/extensions/contact/unified_contact_search_extension.dart';

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

  /// Previous list is kept while the store stream reloads (see
  /// `AsyncValue.value`), so the list does not blink to empty.
  List<UnifiedContact> get allContacts =>
      contacts.value ?? const <UnifiedContact>[];

  List<UnifiedContact> get visibleContacts =>
      allContacts.searchContacts(keyword);
}
