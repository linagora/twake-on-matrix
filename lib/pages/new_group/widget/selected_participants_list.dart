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
    final contactsNotifier =
        widget.newGroupController.selectedContactsMapNotifier;

    return SizedBox(
      width: MediaQuery.of(context).size.width,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        scrollDirection: Axis.horizontal,
        // in 3.10.0, it has an ListenableBuilder for better in this case, temporary solution.
        // no effect in performance,
        child: AnimatedBuilder(
          animation: contactsNotifier,
          builder: (BuildContext context, Widget? child) {
            Widget selectedContactsListWidget;

            if (contactsNotifier.contactsList.isEmpty) {
              selectedContactsListWidget = SizedBox(
                width: MediaQuery.of(context).size.width,
              );
            } else {
              selectedContactsListWidget = Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: contactsNotifier.contactsList
                      .map(
                        (contact) => Tooltip(
                          message: '${contact.displayName}',
                          preferBelow: false,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12.0),
                            onTap: () =>
                                contactsNotifier.unselectContact(contact),
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

            if (contactsNotifier.contactsList.length <= 1) {
              return AnimatedSize(
                curve: Curves.easeIn,
                alignment: Alignment.bottomLeft,
                duration: const Duration(milliseconds: 250),
                child: selectedContactsListWidget,
              );
            }

            return selectedContactsListWidget;
          },
        ),
      ),
    );
  }
}
