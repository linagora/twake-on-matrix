import 'package:fluffychat/presentation/model/presentation_contact.dart';
import 'package:flutter/material.dart';
import 'package:linagora_design_flutter/avatar/round_avatar.dart';
import 'package:linagora_design_flutter/colors/linagora_ref_colors.dart';

class AvatarWithBottomIconWidget extends StatelessWidget {
  final PresentationContact presentationContact;

  final double size;

  final IconData icon;

  const AvatarWithBottomIconWidget({
    super.key,
    required this.presentationContact,
    required this.icon,
    this.size = 56,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
      ),
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          RoundAvatar(text: presentationContact.displayName ?? "@"),
          Container(
            height: 20,
            width: 20,
            decoration: BoxDecoration(
              border: Border.all(
                width: 2,
                color: Colors.white,
              ),
              color: LinagoraRefColors.material().neutral[60],
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(
                icon,
                size: 12,
                color: Theme.of(context).colorScheme.surface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
