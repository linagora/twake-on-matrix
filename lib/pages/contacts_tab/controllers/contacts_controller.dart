import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/domain/contact/entities/unified_contact.dart';
import 'package:twake_chat/pages/contacts_tab/providers/contacts_providers.dart';
import 'package:twake_chat/pages/contacts_tab/states/contacts_state.dart';

part 'contacts_controller.g.dart';

/// Continuous source (the local store) → `Stream<T>` in `build()`, so Riverpod
/// owns the subscription lifecycle and every write re-renders the list.
@riverpod
class ContactsController extends _$ContactsController {
  @override
  Stream<List<UnifiedContact>> build() =>
      ref.watch(contactSyncServiceProvider).watchContacts();

  Future<void> refresh() => ref.read(contactSyncServiceProvider).refresh();

  Future<void> deleteContact(String matrixId) =>
      ref.read(contactSyncServiceProvider).deleteContact(matrixId);
}

/// UI-only search keyword. Kept separate from [ContactsController] so typing
/// does not rebuild (or restart) the store stream.
@riverpod
class ContactsSearchKeyword extends _$ContactsSearchKeyword {
  @override
  String build() => '';

  void update(String keyword) => state = keyword;

  void clear() => state = '';
}

/// Single state the list widget watches.
@riverpod
ContactsState contactsState(Ref ref) => ContactsState(
  contacts: ref.watch(contactsControllerProvider),
  keyword: ref.watch(contactsSearchKeywordProvider),
);
