import 'package:fluffychat/presentation/model/contact/presentation_contact.dart';
import 'package:fluffychat/pages/new_private_chat/widget/expansion_contact_list_tile.dart';
import 'package:fluffychat/widgets/twake_components/twake_icon_button.dart';
import 'package:flutter/material.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

class ExpansionParticipantsList extends StatefulWidget {
  final Set<PresentationContact> contactsList;

  const ExpansionParticipantsList({
    super.key,
    required this.contactsList,
  });

  @override
  State<StatefulWidget> createState() => _ExpansionParticipantsListState();
}

class _ExpansionParticipantsListState extends State<ExpansionParticipantsList> {
  bool isExpanded = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(16.0),
          onTap: () => toggleExpansionList(),
          child: Padding(
            padding: const EdgeInsets.only(left: 8.0, right: 2.0),
            child: Row(
              children: [
                SizedBox(
                  height: 44,
                  child: Row(
                    children: [
                      Text(
                        L10n.of(context)!
                            .participantsCount(widget.contactsList.length),
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: LinagoraRefColors.material().neutral[40],
                            ),
                      ),
                    ],
                  ),
                ),
                const Expanded(child: SizedBox.shrink()),
                TwakeIconButton(
                  paddingAll: 6,
                  buttonDecoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.12),
                  ),
                  icon: isExpanded ? Icons.expand_less : Icons.expand_more,
                  tooltip: isExpanded
                      ? L10n.of(context)!.shrink
                      : L10n.of(context)!.expand,
                ),
              ],
            ),
          ),
        ),
        isExpanded
            ? Expanded(
                child: SingleChildScrollView(
                  key: const ValueKey("participants list"),
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: widget.contactsList
                        .map(
                          (contact) => ExpansionContactListTile(
                            contact: contact,
                          ),
                        )
                        .toList(),
                  ),
                ),
              )
            : const Offstage(),
      ],
    );
  }

  void toggleExpansionList() {
    setState(() {
      isExpanded = !isExpanded;
    });
  }
}
