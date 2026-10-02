import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/domain/contact/entities/unified_contact.dart';
import 'package:twake_chat/pages/contacts_tab/contacts_controller.dart';
import 'package:twake_chat/pages/contacts_tab/providers/contacts_providers.dart';
import 'package:twake_chat/pages/contacts_tab/providers/matrix_profile_providers.dart';

part 'unified_contact_read_providers.g.dart';

/// `matrixId → contact` index built once per store emission, so a single
/// lookup is O(1) instead of a full scan per consumer.
@Riverpod(keepAlive: true)
class UnifiedContactIndex extends _$UnifiedContactIndex {
  @override
  Map<String, UnifiedContact> build() {
    // `value` keeps the previous list while the stream is re-subscribed, so
    // names do not fall back to matrixIds during a reload.
    final contacts = ref.watch(contactsControllerProvider).value;
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

/// Single display entry point for a user: the unified store first, then the
/// Matrix SDK (behind `matrixUserProfileProvider`) as a network fallback.
///
/// Existing widgets replace `FutureBuilder(getProfileFromUserId)` with
/// `ref.watch(contactDisplayProvider(matrixId))`.
@riverpod
Future<UnifiedContact> contactDisplay(Ref ref, String matrixId) async {
  // Reactive path: a widget `ref.watch`ing this provider is re-rendered when
  // its store entry changes.
  final indexed = ref.watch(unifiedContactProvider(matrixId));
  if (indexed != null) return indexed;

  // One-shot path (`container.read(….future)`): Riverpod 3 pauses the store
  // stream when nothing actively listens to it, so the index above may never
  // fill. Read the store directly before falling back to the network.
  // `ref` is unusable after an await (autoDispose may fire meanwhile), so
  // everything that needs it is read before the first await.
  final datasource = ref.watch(matrixProfileDatasourceProvider);
  final userId = ref.read(currentUserIdProvider);
  final service = userId == null
      ? null
      : ref.read(contactSyncServiceProvider(userId));

  final stored = await service?.getContact(matrixId);
  if (stored != null) return stored;

  final profile = await datasource.fetchProfile(matrixId);
  return UnifiedContact(
    matrixId: matrixId,
    canonicalDisplayName: profile?.displayName,
    avatarUrl: profile?.avatarUrl,
  );
}
