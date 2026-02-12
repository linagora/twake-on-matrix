import 'package:dartz/dartz.dart';
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/domain/app_state/user_info/get_user_info_state.dart';
import 'package:fluffychat/domain/model/user_info/user_info.dart';
import 'package:fluffychat/pages/chat/optional_selection_area.dart';
import 'package:fluffychat/pages/profile_info/profile_info_body/profile_info_body_view_style.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions/presence_extension.dart';
import 'package:fluffychat/utils/platform_infos.dart';
import 'package:fluffychat/widgets/avatar/avatar.dart';
import 'package:fluffychat/widgets/matrix.dart';
import 'package:flutter/cupertino.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';

import 'package:matrix/matrix.dart';

class ProfileInfoHeader extends StatelessWidget {
  const ProfileInfoHeader({
    required this.user,
    required this.userInfoNotifier,
    super.key,
  });

  final User user;
  final ValueNotifier<Either<Failure, Success>> userInfoNotifier;

  @override
  Widget build(BuildContext context) {
    final client = Matrix.of(context).client;
    final presence = client.presences[user.id];

    return ValueListenableBuilder(
      valueListenable: userInfoNotifier,
      builder: (context, userInfo, child) {
        final userInfoModel = userInfo
            .getSuccessOrNull<GetUserInfoSuccess>()
            ?.userInfo;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: ProfileInfoBodyViewStyle.avatarPadding,
              child: _buildAvatarWidget(
                context: context,
                userInfo: userInfo,
                userInfoModel: userInfoModel,
              ),
            ),
            OptionalSelectionArea(
              isEnabled: PlatformInfos.isWeb,
              child: _buildDisplayNameWidget(
                context: context,
                userInfo: userInfo,
                userInfoModel: userInfoModel,
              ),
            ),
            if (presence != null) ...[
              const SizedBox(height: 8),
              Text(
                presence.getLocalizedStatusMessage(context),
                style: presence.getPresenceTextStyle(context),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildAvatarWidget({
    required BuildContext context,
    required Either<Failure, Success> userInfo,
    required UserInfo? userInfoModel,
  }) {
    return userInfo.fold(
      (failure) {
        return Avatar(
          mxContent: user.avatarUrl,
          name: userInfoModel?.displayName ?? user.calcDisplayname(),
          size: 160,
        );
      },
      (success) {
        if (success is GettingUserInfo) {
          return const SizedBox(
            width: 160,
            height: 160,
            child: Center(child: CupertinoActivityIndicator(animating: true)),
          );
        }
        if (success is GetUserInfoSuccess) {
          return Avatar(
            mxContent: userInfoModel?.avatarUrl != null
                ? Uri.parse(userInfoModel?.avatarUrl ?? '')
                : user.avatarUrl,
            name: userInfoModel?.displayName ?? user.calcDisplayname(),
            size: 160,
          );
        }
        return Avatar(
          mxContent: user.avatarUrl,
          name: userInfoModel?.displayName ?? user.calcDisplayname(),
          size: 160,
        );
      },
    );
  }

  Widget _buildDisplayNameWidget({
    required BuildContext context,
    required Either<Failure, Success> userInfo,
    required UserInfo? userInfoModel,
  }) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position:
                Tween<Offset>(
                  begin: const Offset(0, 0.5),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(parent: animation, curve: Curves.easeOut),
                ),
            child: child,
          ),
        );
      },
      child: userInfo.fold(
        (failure) {
          return Text(
            user.calcDisplayname(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: LinagoraTextStyle.material().bodyMedium2.copyWith(
              color: LinagoraSysColors.material().onSurface,
            ),
          );
        },
        (success) {
          if (success is GettingUserInfo) {
            return SizedBox(
              height: LinagoraTextStyle.material().bodyMedium2.height,
            );
          }
          if (success is GetUserInfoSuccess) {
            return Text(
              userInfoModel?.displayName ?? user.calcDisplayname(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: LinagoraTextStyle.material().bodyMedium2.copyWith(
                color: LinagoraSysColors.material().onSurface,
              ),
            );
          }
          return Text(
            user.calcDisplayname(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: LinagoraTextStyle.material().bodyMedium2.copyWith(
              color: LinagoraSysColors.material().onSurface,
            ),
          );
        },
      ),
    );
  }
}
