import 'package:fluffychat/pages/new_group/new_group.dart';
import 'package:fluffychat/presentation/model/presentation_contact.dart';
import 'package:fluffychat/pages/new_private_chat/widget/expansion_contact_list_tile.dart';
import 'package:fluffychat/widgets/twake_components/twake_icon_button.dart';
import 'package:flutter/material.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

class ExpansionParticipantsList extends StatelessWidget {

  final Set<PresentationContact> contactsList;

  final NewGroupController newGroupController;

  const ExpansionParticipantsList({
    super.key,
    required this.contactsList,
    required this.newGroupController,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(16.0),
          onTap: () => newGroupController.toggleExpansionList(),
          child: Padding(
            padding: const EdgeInsets.only(left: 8.0, right: 2.0),
            child: Row(
              children: [
                SizedBox(
                  height: 44,
                  child: Row(
                    children: [
                      Text(L10n.of(context)!.participantsCount(contactsList.length),
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: LinagoraRefColors.material().neutral[40],
                        )),
                    ],
                  ),
                ),
                const Expanded(child: SizedBox.shrink()),
                ValueListenableBuilder(
                  valueListenable: newGroupController.isExpandedParticipants,
                  builder: (context, isExpanded, child) {
                    if (isExpanded) {
                      return _iconExpanded(context);
                    } else {
                      return _iconNotExpand(context);
                    }
                  }
                ),
              ],
            ),
          ),
        ),
        ValueListenableBuilder(
          valueListenable: newGroupController.isExpandedParticipants,
          builder: (context, isExpanded, child) {
            if (isExpanded) {
              return Expanded(
                child: SingleChildScrollView(
                  key: const ValueKey("participants list"),
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: contactsList
                      .map((contact) => ExpansionContactListTile(contact: contact))
                      .toList(),
                  ),
                ),
              );
            } else {
              return const Offstage();
            }
          }
        )
      ],
    );
  }

  Widget _iconExpanded(BuildContext context) {
    return TwakeIconButton(
      paddingAll: 6,
      buttonDecoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.12),
      ),
      icon: Icons.expand_less,
      tooltip: L10n.of(context)!.shrink,
    );
  }

  Widget _iconNotExpand(BuildContext context) {
    return TwakeIconButton(
      paddingAll: 6,
      buttonDecoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.12),
      ),
      icon: Icons.expand_more,
      tooltip: L10n.of(context)!.expand,
    );
  }
}