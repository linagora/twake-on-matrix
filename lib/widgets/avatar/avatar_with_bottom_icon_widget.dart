import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/presentation/model/contact/presentation_contact.dart';
import 'package:fluffychat/utils/manager/twake_user_info_manager/twake_user_info_extension.dart';
import 'package:fluffychat/utils/manager/twake_user_info_manager/twake_user_info_manager.dart';
import 'package:fluffychat/widgets/avatar/avatar.dart';
import 'package:fluffychat/widgets/matrix.dart';
import 'package:flutter/material.dart';
import 'package:linagora_design_flutter/colors/linagora_ref_colors.dart';
import 'package:matrix/matrix.dart';

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
          if (presentationContact.matrixId != null)
            FutureBuilder<Profile>(
              future: getIt
                  .get<TwakeUserInfoManager>()
                  .getTwakeProfileFromUserId(
                    client: Matrix.of(context).client,
                    userId: presentationContact.matrixId!,
                    getFromRooms: false,
                  )
                  .then((twakeProfile) => twakeProfile.toMatrixProfile()),
              builder: ((context, snapshot) {
                return Avatar(
                  mxContent: snapshot.data?.avatarUrl,
                  name: presentationContact.displayName,
                );
              }),
            ),
          if (presentationContact.matrixId == null)
            Avatar(
              name: presentationContact.displayName,
            ),
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
