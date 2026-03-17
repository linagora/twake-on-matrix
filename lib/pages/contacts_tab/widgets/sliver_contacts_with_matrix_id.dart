import 'package:fluffychat/domain/app_state/contact/get_contacts_state.dart';
import 'package:fluffychat/pages/contacts_tab/contacts_tab.dart';
import 'package:fluffychat/pages/contacts_tab/contacts_tab_view_style.dart';
import 'package:fluffychat/pages/new_private_chat/widget/expansion_contact_list_tile.dart';
import 'package:fluffychat/pages/new_private_chat/widget/loading_contact_widget.dart';
import 'package:fluffychat/pages/new_private_chat/widget/no_contacts_found.dart';
import 'package:fluffychat/presentation/model/contact/presentation_contact.dart';
import 'package:fluffychat/presentation/model/contact/presentation_contact_success.dart';
import 'package:fluffychat/utils/platform_infos.dart';
import 'package:fluffychat/widgets/sliver_expandable_list.dart';
import 'package:flutter/material.dart';
import 'package:fluffychat/generated/l10n/app_localizations.dart';
import 'package:matrix/matrix.dart';

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

class _ExternalContactTile extends StatefulWidget {
  const _ExternalContactTile({required this.controller, required this.contact});

  final ContactsTabController controller;
  final PresentationContact contact;

  @override
  State<_ExternalContactTile> createState() => _ExternalContactTileState();
}

class _ExternalContactTileState extends State<_ExternalContactTile> {
  Future<CachedProfileInformation>? _profileFuture;
  String? _currentMatrixId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _fetchProfileIfNeeded();
  }

  @override
  void didUpdateWidget(covariant _ExternalContactTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.contact.matrixId != widget.contact.matrixId) {
      _fetchProfileIfNeeded();
    }
  }

  void _fetchProfileIfNeeded() {
    final matrixId = widget.contact.matrixId;
    if (matrixId == null) {
      _currentMatrixId = null;
      _profileFuture = null;
      return;
    }
    if (_currentMatrixId != matrixId) {
      _currentMatrixId = matrixId;
      _profileFuture = widget.controller.client.getUserProfile(
        matrixId,
        maxCacheAge: Duration.zero,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<CachedProfileInformation>(
      future: _profileFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SliverToBoxAdapter(child: LoadingContactWidget());
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(
                left: ContactsTabViewStyle.padding,
                top: ContactsTabViewStyle.padding,
              ),
              child: NoContactsFound(
                keyword: widget.controller.textEditingController.text,
              ),
            ),
          );
        }

        final profile = snapshot.data!;
        final validatedContact = PresentationContact(
          matrixId: widget.contact.matrixId,
          displayName: profile.displayname ?? widget.contact.displayName,
          type: widget.contact.type,
        );

        return SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: ContactsTabViewStyle.padding,
            ),
            child: ExpansionContactListTile(
              contact: validatedContact,
              highlightKeyword: widget.controller.textEditingController.text,
              enableInvitation: widget.controller.supportInvitation(),
              onContactTap: () => widget.controller.onContactTap(
                context: context,
                path: 'rooms',
                contact: validatedContact,
              ),
            ),
          ),
        );
      },
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
        enableInvitation: controller.supportInvitation(),
        onContactTap: () => controller.onContactTap(
          context: context,
          path: 'rooms',
          contact: contact,
        ),
      ),
    );
  }
}
