import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/domain/contact/entities/unified_contact.dart';
import 'package:twake_chat/pages/contacts_tab/controllers/contacts_controller.dart';

part 'unified_contact_read_providers.g.dart';

/// Read-only lookup of a single contact from the unified store.
///
/// Consumers migrate from `client.getProfileFromUserId()` (network) to this
/// provider (local, already merged) screen by screen. Returns `null` while the
/// store has no entry for [matrixId], so call sites can keep a fallback.
@riverpod
UnifiedContact? unifiedContact(Ref ref, String matrixId) {
  final contacts = ref.watch(contactsControllerProvider).asData?.value;
  if (contacts == null) return null;
  for (final contact in contacts) {
    if (contact.matrixId == matrixId) return contact;
  }
  return null;
}
