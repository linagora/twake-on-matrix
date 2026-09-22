import 'package:twake_chat/domain/app_state/contact/get_contacts_state.dart';
import 'package:twake_chat/pages/contacts_tab/contacts_tab.dart';
import 'package:twake_chat/pages/contacts_tab/contacts_tab_view_style.dart';
import 'package:twake_chat/pages/contacts_tab/providers/unified_contact_read_providers.dart';
import 'package:twake_chat/pages/new_private_chat/widget/expansion_contact_list_tile.dart';
import 'package:twake_chat/pages/new_private_chat/widget/loading_contact_widget.dart';
import 'package:twake_chat/pages/new_private_chat/widget/no_contacts_found.dart';
import 'package:twake_chat/presentation/model/contact/presentation_contact.dart';
import 'package:twake_chat/presentation/model/contact/presentation_contact_success.dart';
import 'package:twake_chat/utils/platform_infos.dart';
import 'package:twake_chat/widgets/sliver_expandable_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';

class SliverContactsWithMatrixId extends StatelessWidget {
  const SliverContactsWithMatrixId({required this.controller, super.key});

  final ContactsTabController controller;

  @override
  Widget build(BuildContext context) {
    const empty = SliverToBoxAdapter();
    return ValueListenableBuilder(
      valueListenable: controller.presentationContactNotifier,
      builder: (context, state, _) {
        return state.fold((_) => empty, (success) {
          if (success is ContactsLoading) {
            return empty;
          }

          if (success is PresentationExternalContactSuccess) {
            if (controller.presentationRecentContactNotifier.value.isNotEmpty) {
              return empty;
            }
            if (!PlatformInfos.isWeb) {
              if (controller.phoneBookFilterSuccess) {
                return empty;
              }
            }
            return _ExternalContactTile(
              controller: controller,
              contact: success.contact,
            );
          }

          if (success is PresentationContactsSuccess) {
            final contacts = success.contacts
                .where((c) => c.matrixId != null && c.matrixId!.isNotEmpty)
                .toList();
            if (contacts.isEmpty) {
              return empty;
            }
            return SliverExpandableList(
              title: L10n.of(context)!.linagoraContactsCount(contacts.length),
              itemCount: contacts.length,
              itemBuilder: (context, index) => _ContactTile(
                contact: contacts[index],
                controller: controller,
              ),
            );
          }

          return empty;
        });
      },
    );
  }
}

class _ExternalContactTile extends ConsumerWidget {
  const _ExternalContactTile({required this.controller, required this.contact});

  final ContactsTabController controller;
  final PresentationContact contact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matrixId = contact.matrixId;
    if (matrixId == null || matrixId.isEmpty) {
      return const SliverToBoxAdapter();
    }

    final displayAsync = ref.watch(contactDisplayProvider(matrixId));
    final unified = displayAsync.asData?.value;
    final displayName = unified?.resolvedDisplayName ?? contact.displayName;

    if (displayName == null || displayName.trim().isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.only(
            left: ContactsTabViewStyle.padding,
            top: ContactsTabViewStyle.padding,
          ),
          child: NoContactsFound(
            keyword: controller.textEditingController.text,
          ),
        ),
      );
    }

    if (displayAsync.isLoading) {
      return const SliverToBoxAdapter(child: LoadingContactWidget());
    }

    final validatedContact = PresentationContact(
      matrixId: contact.matrixId,
      displayName: displayName,
      type: contact.type,
    );

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: ContactsTabViewStyle.padding,
        ),
        child: ExpansionContactListTile(
          contact: validatedContact,
          highlightKeyword: controller.textEditingController.text,
          enableInvitation: controller.isInvitationEnabled,
          onContactTap: () => controller.onContactTap(
            context: context,
            path: 'rooms',
            contact: validatedContact,
          ),
        ),
      ),
    );
  }
}

class _ContactTile extends StatelessWidget {
  const _ContactTile({required this.contact, required this.controller});

  final PresentationContact contact;
  final ContactsTabController controller;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: ContactsTabViewStyle.padding,
      ),
      child: ExpansionContactListTile(
        contact: contact,
        highlightKeyword: controller.textEditingController.text,
        enableInvitation: controller.isInvitationEnabled,
        onContactTap: () => controller.onContactTap(
          context: context,
          path: 'rooms',
          contact: contact,
        ),
      ),
    );
  }
}
