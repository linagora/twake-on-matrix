import 'package:fluffychat/pages/contacts/presentation/model/presentation_contact.dart';
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
    return Padding(
      padding: const EdgeInsets.only(top: 8.0, bottom: 12.0),
      child: InkWell(
        onTap: onTap,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RoundAvatar(
              text: contact.displayName,
              size: 48,
            ),
            const SizedBox(width: 12.0,),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(contact.displayName, style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 17.0,
                  letterSpacing: -0.15,
                  color: Theme.of(context).colorScheme.onSurface
                )),
                if (contact.matrixId != null)
                  Text(contact.matrixId!,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      letterSpacing: 0.1,
                      color: LinagoraRefColors.material().neutral[30],
                    ),
                  ),
                Text(contact.email,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    letterSpacing: 0.25,
                    color: LinagoraRefColors.material().neutral[30],
                  ),)
              ],
            )
          ],
        ),
      ),
    );
  }
  
}