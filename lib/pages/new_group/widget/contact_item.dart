import 'package:collection/collection.dart';
import 'package:fluffychat/domain/model/room/room_extension.dart';
import 'package:fluffychat/generated/l10n/app_localizations.dart';
import 'package:fluffychat/pages/new_group/selected_contacts_map_change_notifier.dart';
import 'package:fluffychat/pages/new_group/widget/contacts_selection_list_style.dart';
import 'package:fluffychat/pages/new_private_chat/widget/expansion_contact_list_tile.dart';
import 'package:fluffychat/presentation/model/contact/presentation_contact.dart';
import 'package:fluffychat/utils/twake_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:linagora_design_flutter/colors/linagora_sys_colors.dart';
import 'package:matrix/matrix.dart';

class ContactItem extends StatelessWidget {
  final PresentationContact contact;
  final SelectedContactsMapChangeNotifier selectedContactsMapNotifier;
  final VoidCallback? onSelectedContact;
  final bool disabled;
  final double paddingTop;
  final String highlightKeyword;
  final bool bannedHighlight;
  final Room? room;

  const ContactItem({
    super.key,
    required this.contact,
    required this.selectedContactsMapNotifier,
    this.onSelectedContact,
    this.highlightKeyword = '',
    this.disabled = false,
    this.paddingTop = 0,
    this.bannedHighlight = false,
    this.room,
  });

  bool get canUnban {
    return room == null ||
        room!.canBan ||
        room!.getBannedMembers().none((u) => u.id == contact.matrixId);
  }

  bool canSelect(BuildContext context) {
    if (!bannedHighlight) return true;
    if (!canUnban) {
      TwakeSnackBar.show(
        context,
        L10n.of(context)!.cannotInviteBannedMember,
      );
      return false;
    }

    return true;
  }

  @override
  Widget build(BuildContext context) {
    final contactNotifier =
        selectedContactsMapNotifier.getNotifierAtContact(contact);
    return Stack(
      children: [
        InkWell(
          key: ValueKey(contact.matrixId),
          onTap: disabled
              ? null
              : () {
                  if (!canSelect(context)) return;
                  onSelectedContact?.call();
                  selectedContactsMapNotifier.onContactTileTap(
                    context,
                    contact,
                  );
                },
          borderRadius: ContactsSelectionListStyle.contactItemBorderRadius,
          child: Container(
            width: MediaQuery.of(context).size.width,
            margin: ContactsSelectionListStyle.contactItemPadding,
            padding: ContactsSelectionListStyle.checkBoxPadding(paddingTop),
            child: Row(
              children: [
                ValueListenableBuilder<bool>(
                  valueListenable: contactNotifier,
                  builder: (context, isCurrentSelected, child) {
                    return Checkbox(
                      value: disabled || contactNotifier.value,
                      onChanged: disabled
                          ? null
                          : (newValue) {
                              if (!canSelect(context)) return;
                              onSelectedContact?.call();
                              selectedContactsMapNotifier.onContactTileTap(
                                context,
                                contact,
                              );
                            },
                    );
                  },
                ),
                Expanded(
                  child: ExpansionContactListTile(
                    contact: contact,
                    highlightKeyword: highlightKeyword,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (!canUnban)
          Positioned.fill(
            child: IgnorePointer(
              child: ColoredBox(
                color: LinagoraSysColors.material()
                    .onPrimary
                    .withValues(alpha: 0.5),
              ),
            ),
          ),
      ],
    );
  }
}
