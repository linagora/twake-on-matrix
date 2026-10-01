import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/domain/contact/entities/unified_contact.dart';
import 'package:twake_chat/pages/contacts_tab/contacts_view_model.dart';

part 'unified_contact_read_providers.g.dart';

/// `matrixId → contact` index built once per store emission, so a single
/// lookup is O(1) instead of a full scan per consumer.
@riverpod
class UnifiedContactIndex extends _$UnifiedContactIndex {
  @override
  Map<String, UnifiedContact> build() {
    final contacts = ref.watch(contactsViewModelProvider).asData?.value;
    if (contacts == null) return const <String, UnifiedContact>{};
    return {for (final contact in contacts) contact.matrixId: contact};
  }
}

/// Read-only lookup of a single contact from the unified store.
///
/// Consumers migrate from `client.getProfileFromUserId()` (network) to this
/// provider (local, already merged) screen by screen. Returns `null` while the
/// store has no entry for [matrixId], so call sites can keep a fallback. The
/// `select` ensures a widget only rebuilds when its own contact changes, not
/// on every store emission.
@riverpod
UnifiedContact? unifiedContact(Ref ref, String matrixId) =>
    ref.watch(unifiedContactIndexProvider.select((index) => index[matrixId]));
