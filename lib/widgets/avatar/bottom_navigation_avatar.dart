import 'package:fluffychat/widgets/avatar/avatar.dart';
import 'package:fluffychat/widgets/avatar/bottom_navigation_avatar_style.dart';
import 'package:flutter/material.dart';
import 'package:linagora_design_flutter/colors/linagora_sys_colors.dart';
import 'package:matrix/matrix.dart';

class BottomNavigationAvatar extends StatelessWidget {
  final bool isSelected;
  final ValueNotifier<Profile?> profile;

  const BottomNavigationAvatar({
    super.key,
    required this.isSelected,
    required this.profile,
  });
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Profile?>(
      key: key,
      valueListenable: profile,
      builder: (context, profile, child) {
        return Container(
          decoration: isSelected
              ? ShapeDecoration(
                  shape: CircleBorder(
                    side: BorderSide(
                      width:
                          BottomNavigationAvatarStyle.selectedavatarBorderWidth,
                      color: LinagoraSysColors.material().primary,
                    ),
                  ),
                )
              : null,
          child: Avatar(
            name: profile?.displayName,
            mxContent: profile?.avatarUrl,
            size: BottomNavigationAvatarStyle.avatarSize,
            fontSize: BottomNavigationAvatarStyle.avatarFontSize,
          ),
        );
      },
    );
  }
}
