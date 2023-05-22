import 'package:fluffychat/pages/contacts/presentation/model/presentation_contact.dart';
import 'package:fluffychat/pages/new_private_chat/widget/contact_status_widget.dart';
import 'package:flutter/material.dart';
import 'package:linagora_design_flutter/avatar/round_avatar.dart';
import 'package:linagora_design_flutter/colors/linagora_ref_colors.dart';

typedef OnExpansionListTileTap = void Function();

class ExpansionContactListTile extends StatelessWidget {

  final PresentationContact contact;

  final OnExpansionListTileTap onTap;

  const ExpansionContactListTile({
    super.key,
    required this.contact,
    required this.onTap
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16.0),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(left:8.0, top: 8.0, bottom: 12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RoundAvatar(
              text: contact.displayName ?? "@",
              size: 48,
            ),
            const SizedBox(width: 12.0,),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (contact.displayName != null)...[
                    IntrinsicWidth(
                      child: Row(
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Flexible(
                                  child: Text(contact.displayName!, style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 17.0,
                                    letterSpacing: -0.15,
                                    color: Theme.of(context).colorScheme.onSurface,
                                    overflow: TextOverflow.ellipsis,
                                  )),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8.0,),
                          ContactStatusWidget(status: contact.status,),
                        ],
                      ),
                    ),
                  ],
                  if (contact.matrixId != null)
                    Text(contact.matrixId!,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        letterSpacing: 0.1,
                        color: LinagoraRefColors.material().neutral[30],
                      ),
                    ),
                  if (contact.email != null) 
                    Text(contact.email!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        letterSpacing: 0.25,
                        color: LinagoraRefColors.material().neutral[30],
                      ),)
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
  
}