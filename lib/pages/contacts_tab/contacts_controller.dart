import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/domain/contact/entities/unified_contact.dart';
import 'package:twake_chat/pages/contacts_tab/providers/contacts_providers.dart';
import 'package:twake_chat/pages/contacts_tab/states/contacts_state.dart';

part 'contacts_controller.g.dart';

/// Continuous source (the local store) → `Stream<T>` in `build()`, so Riverpod
/// owns the subscription lifecycle and every write re-renders the list.
///
/// Session-wide read model (`keepAlive`): one store subscription shared by
/// every screen, and one-shot readers (`.future`) are never disposed before
/// the first emission.
@Riverpod(keepAlive: true)
class ContactsController extends _$ContactsController {
  @override
  Stream<List<UnifiedContact>> build() {
    final userId = ref.watch(currentUserIdProvider);
    // No account: an empty list (not an empty stream) so `.future` resolves.
    if (userId == null) return Stream.value(const <UnifiedContact>[]);
    return ref.watch(contactSyncServiceProvider(userId)).watchContacts();
  }

  Future<void> refresh({bool resolvePhonebook = false}) async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;
    await ref
        .read(contactSyncServiceProvider(userId))
        .refresh(resolvePhonebook: resolvePhonebook);
  }
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
