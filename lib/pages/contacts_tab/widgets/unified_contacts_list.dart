import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:twake_chat/domain/contact/entities/unified_contact.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:twake_chat/pages/contacts_tab/contacts_controller.dart';

/// Read-only list backed by the unified contact store.
///
/// This is the new presentation path (PR4-A): it is not wired into the live
/// Contacts tab yet, so the legacy permission / warning-banner flow is
/// untouched.
class UnifiedContactsList extends ConsumerWidget {
  const UnifiedContactsList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(contactsStateProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: TextField(
            onChanged: (value) =>
                ref.read(contactsSearchKeywordProvider.notifier).update(value),
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
          ),
        ),
        Expanded(
          child: state.contacts.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(child: Text(error.toString())),
            data: (_) {
              // Computed once per build: the getter re-filters the whole list
              // on every call, so reading it per item would be O(n²).
              final visibleContacts = state.visibleContacts;
              return RefreshIndicator(
                onRefresh: () =>
                    ref.read(contactsControllerProvider.notifier).refresh(),
                child: visibleContacts.isEmpty
                    ? const _EmptyContacts()
                    : ListView.builder(
                        itemCount: visibleContacts.length,
                        itemBuilder: (context, index) {
                          final contact = visibleContacts[index];
                          return ListTile(
                            key: ValueKey(contact.matrixId),
                            leading: CircleAvatar(
                              child: Text(_initials(contact)),
                            ),
                            title: Text(contact.displayNameOrId),
                            subtitle: contact.resolvedDisplayName == null
                                ? null
                                : Text(contact.matrixId),
                          );
                        },
                      ),
              );
            },
          ),
        ),
      ],
    );
  }

  String _initials(UnifiedContact contact) {
    final name = contact.resolvedDisplayName?.trim() ?? '';
    if (name.isEmpty) return '?';
    return name[0].toUpperCase();
  }
}

class _EmptyContacts extends StatelessWidget {
  const _EmptyContacts();

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        Padding(
          padding: const EdgeInsets.all(32),
          child: Center(child: Text(L10n.of(context)!.soonThereHaveContacts)),
        ),
      ],
    );
  }
}
