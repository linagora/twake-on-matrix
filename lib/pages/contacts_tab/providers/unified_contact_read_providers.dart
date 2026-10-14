import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/domain/contact/entities/unified_contact.dart';
import 'package:twake_chat/pages/contacts_tab/providers/contacts_providers.dart';
import 'package:twake_chat/pages/contacts_tab/providers/matrix_profile_providers.dart';

part 'unified_contact_read_providers.g.dart';

/// Contacts of one account. Family-keyed by the account so a value can only
/// ever be that account's: after a switch the new key starts without a value
/// (nothing of the previous account is served), and re-subscribing
/// `contactsControllerProvider` leaves it untouched (no flash).
@riverpod
Stream<List<UnifiedContact>> accountContacts(Ref ref, String userId) =>
    ref.watch(contactSyncServiceProvider(userId)).watchContacts();

/// `matrixId → contact` index built once per store emission, so a single
/// lookup is O(1) instead of a full scan per consumer.
///
/// Empty without an account, and until the current account's store has
/// emitted.
@Riverpod(keepAlive: true)
class UnifiedContactIndex extends _$UnifiedContactIndex {
  @override
  Map<String, UnifiedContact> build() {
    final userId = ref.watch(currentUserIdProvider);
    if (userId == null) return const <String, UnifiedContact>{};
    final contacts = ref.watch(accountContactsProvider(userId)).value;
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
  final datasource = ref.watch(matrixProfileDatasourceProvider);
  if (indexed != null) return indexed;

  // One-shot path (`container.read(….future)`): Riverpod 3 pauses the store
  // stream when nothing actively listens to it, so the index above may never
  // fill. Read the store directly before falling back to the network.
  // `ref` is unusable after an await (autoDispose may fire meanwhile), so
  // everything that needs it is read before the first await.
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

/// Avatar of a user the store holds no avatar for: the homeserver profile,
/// asked once (through `matrixUserProfileProvider`) and kept five minutes, a
/// failure too (the datasource answers null), so rebuilds and tiles coming
/// back on screen do not ask again. The profile is never awaited by
/// [contactDisplay]: names show at once, the avatar follows.
@riverpod
Future<Uri?> homeserverAvatar(Ref ref, String matrixId) async {
  final link = ref.keepAlive();
  final timer = Timer(const Duration(minutes: 5), link.close);
  ref.onDispose(timer.cancel);
  final profile = await ref.watch(matrixUserProfileProvider(matrixId).future);
  final avatarUrl = profile?.avatarUrl;
  return avatarUrl == null ? null : Uri.tryParse(avatarUrl);
}

/// Avatar for a row: the store's, else the homeserver's once it answers.
@riverpod
Uri? contactAvatar(Ref ref, String matrixId) {
  final contact = ref.watch(contactDisplayProvider(matrixId)).value;
  if (contact == null) return null;
  return contact.avatarUri ??
      ref.watch(homeserverAvatarProvider(matrixId)).value;
}
