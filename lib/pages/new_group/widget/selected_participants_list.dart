import 'package:fluffychat/presentation/model/presentation_contact.dart';
import 'package:fluffychat/pages/new_group/new_group.dart';
import 'package:fluffychat/widgets/avatar/avatar_with_bottom_icon_widget.dart';
import 'package:flutter/material.dart';

class SelectedParticipantsList extends StatefulWidget {

  final NewGroupController newGroupController;

  const SelectedParticipantsList({
    super.key,
    required this.newGroupController,
  });

  @override
  State<StatefulWidget> createState() => _SelectedParticipantsListState();
}

class _SelectedParticipantsListState extends State<SelectedParticipantsList> {
  @override
  Widget build(BuildContext context) {
    final contactsNotifier = widget.newGroupController.selectedContactsMapNotifier;

    return SizedBox(
      width: MediaQuery.of(context).size.width,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        scrollDirection: Axis.horizontal,
        child: ValueListenableBuilder<Map<PresentationContact, bool>>(
          valueListenable: contactsNotifier,
          builder: (context, selectedContacts, child) {
            Widget selectedContactsListWidget;
            if (selectedContacts.isEmpty) {
              selectedContactsListWidget = SizedBox(width: MediaQuery.of(context).size.width,);
            } else {
              selectedContactsListWidget = Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: selectedContacts.keys
                    .map((contact) => Tooltip(
                      message: '${contact.displayName}',
                      preferBelow: false,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12.0),
                        onTap: () => widget.newGroupController.unselectContact(contact),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: AvatarWithBottomIconWidget(
                            presentationContact: contact,
                            icon: Icons.close,
                            ),
                        ),
                      ),
                    ),
                    )
                    .toList(),
                ),
              );
            }

            if (selectedContacts.length <= 1) {
              return AnimatedSize(
                curve: Curves.easeIn,
                alignment: Alignment.bottomLeft,
                duration: const Duration(milliseconds: 250),
                child: selectedContactsListWidget,
              );
            }
          
            return selectedContactsListWidget;
          }
        ),
      ),
    );
  }
}