import 'package:fluffychat/pages/new_group/contacts_selection.dart';
import 'package:fluffychat/pages/new_group/widget/selected_participants_list_style.dart';
import 'package:fluffychat/utils/platform_infos.dart';
import 'package:fluffychat/widgets/avatar/avatar.dart';
import 'package:fluffychat/widgets/matrix.dart';
import 'package:flutter/material.dart';
import 'package:linagora_design_flutter/colors/linagora_ref_colors.dart';
import 'package:matrix/matrix.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

class SelectedParticipantsList extends StatefulWidget {
  final ContactsSelectionController contactsSelectionController;

  const SelectedParticipantsList({
    super.key,
    required this.contactsSelectionController,
  });

  @override
  State<StatefulWidget> createState() => _SelectedParticipantsListState();
}

class _SelectedParticipantsListState extends State<SelectedParticipantsList> {
  @override
  Widget build(BuildContext context) {
    final contactsNotifier =
        widget.contactsSelectionController.selectedContactsMapNotifier;

    return AnimatedSize(
      curve: Curves.easeIn,
      alignment: Alignment.bottomCenter,
      duration: const Duration(milliseconds: 250),
      child: SizedBox(
        width: MediaQuery.sizeOf(context).width,
        child: ListenableBuilder(
          listenable: contactsNotifier,
          builder: (context, Widget? child) {
            if (contactsNotifier.contactsList.isEmpty) {
              return const SizedBox.shrink();
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: SelectedParticipantsListStyle.paddingAll,
                  child: Wrap(
                    spacing: 8.0,
                    runSpacing: PlatformInfos.isWeb ? 4.0 : 0.0,
                    children: contactsNotifier.contactsList.map((contact) {
                      return InputChip(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            SelectedParticipantsListStyle.borderRadiusChip,
                          ),
                          side: BorderSide(
                            color: Theme.of(context).colorScheme.outline,
                            width: 1.0,
                          ),
                        ),
                        labelPadding:
                            SelectedParticipantsListStyle.labelChipPadding,
                        padding: const EdgeInsets.all(0),
                        label: Text(
                          contact.displayName ?? contact.matrixId ?? '',
                          style:
                              Theme.of(context).textTheme.labelLarge?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                        ),
                        avatar: contact.matrixId != null
                            ? FutureBuilder<Profile>(
                                future: Matrix.of(context)
                                    .client
                                    .getProfileFromUserId(
                                      contact.matrixId!,
                                      getFromRooms: false,
                                    ),
                                builder: ((context, snapshot) {
                                  return Avatar(
                                    mxContent: snapshot.data?.avatarUrl,
                                    name: contact.displayName,
                                    size: SelectedParticipantsListStyle
                                        .avatarChipSize,
                                  );
                                }),
                              )
                            : Avatar(
                                name: contact.displayName,
                                size: SelectedParticipantsListStyle
                                    .avatarChipSize,
                              ),
                        onDeleted: () {
                          widget.contactsSelectionController
                              .selectedContactsMapNotifier
                              .unselectContact(contact);
                        },
                      );
                    }).toList(),
                  ),
                ),
                Divider(
                  color: Theme.of(context)
                      .colorScheme
                      .surfaceTint
                      .withOpacity(0.16),
                ),
                const SizedBox(
                  height: 4.0,
                ),
                Padding(
                  padding: SelectedParticipantsListStyle.contactPadding,
                  child: Row(
                    children: [
                      Text(
                        '${L10n.of(context)!.selectedUsers}: ${contactsNotifier.contactsList.length}',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: LinagoraRefColors.material().tertiary[20],
                            ),
                      ),
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            InkWell(
                              onTap: () => widget.contactsSelectionController
                                  .selectedContactsMapNotifier
                                  .unselectAllContacts(),
                              child: Text(
                                L10n.of(context)!.clearAllSelected,
                                style: Theme.of(context)
                                    .textTheme
                                    .labelLarge
                                    ?.copyWith(
                                      color: LinagoraRefColors.material()
                                          .tertiary[20],
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
