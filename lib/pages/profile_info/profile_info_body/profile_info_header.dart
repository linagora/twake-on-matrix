import 'package:dartz/dartz.dart' hide State;
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/domain/app_state/user_info/get_user_info_state.dart';
import 'package:fluffychat/domain/model/user_info/user_info.dart';
import 'package:fluffychat/pages/profile_info/profile_info_body/profile_info_body_view_style.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions/presence_extension.dart';
import 'package:fluffychat/utils/responsive/responsive_utils.dart';
import 'package:fluffychat/widgets/avatar/avatar.dart';
import 'package:fluffychat/widgets/matrix.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';
import 'package:matrix/matrix.dart';

class ProfileInfoHeader extends StatefulWidget {
  const ProfileInfoHeader({
    required this.user,
    required this.userInfoNotifier,
    required this.animationController,
    required this.onAvatarInfoTap,
    super.key,
  });

  final User user;
  final ValueNotifier<Either<Failure, Success>> userInfoNotifier;
  final AnimationController animationController;
  final VoidCallback onAvatarInfoTap;

  @override
  State<ProfileInfoHeader> createState() => _ProfileInfoHeaderState();
}

class _ProfileInfoHeaderState extends State<ProfileInfoHeader> {
  bool isTextSelected = false;

  final responsive = getIt.get<ResponsiveUtils>();

  @override
  Widget build(BuildContext context) {
    if (responsive.isMobile(context)) {
      return _buildMobileHeader(context);
    }
    return _buildNonMobileHeader(context);
  }

  Widget _buildMobileHeader(BuildContext context) {
    final client = Matrix.of(context).client;
    final presence = client.presences[widget.user.id];
    final sysColors = LinagoraSysColors.material();

    return ValueListenableBuilder(
      valueListenable: widget.userInfoNotifier,
      builder: (context, userInfo, child) {
        final userInfoModel =
            userInfo.getSuccessOrNull<GetUserInfoSuccess>()?.userInfo;
        final displayName =
            userInfoModel?.displayName ?? widget.user.calcDisplayname();

        return SelectionArea(
          onSelectionChanged: (value) {
            final newSelected = value != null && value.plainText.isNotEmpty;
            if (newSelected != isTextSelected) {
              setState(() => isTextSelected = newSelected);
            }
          },
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              if (!isTextSelected) {
                widget.onAvatarInfoTap();
                return;
              }
              FocusScope.of(context).unfocus();
            },
            child: Container(
              height: Tween<double>(
                begin: ProfileInfoBodyViewStyle.minAvatarBackgroundHeight,
                end: ProfileInfoBodyViewStyle.maxAvatarBackgroundHeight,
              ).transform(widget.animationController.value),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const SizedBox(
                    height: ProfileInfoBodyViewStyle.avatarSize,
                    width: ProfileInfoBodyViewStyle.avatarSize,
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Tween<Alignment>(
                      begin: Alignment.center,
                      end: Alignment.centerLeft,
                    ).transform(widget.animationController.value),
                    child: Text(
                      displayName,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: ColorTween(
                              begin: sysColors.onSurface,
                              end: sysColors.onPrimary,
                            ).transform(widget.animationController.value),
                            fontWeight: FontWeight.bold,
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (presence != null) ...[
                    const SizedBox(height: 8),
                    Align(
                      alignment: Tween<Alignment>(
                        begin: Alignment.center,
                        end: Alignment.centerLeft,
                      ).transform(widget.animationController.value),
                      child: Text(
                        presence.getLocalizedStatusMessage(context),
                        style: presence.getPresenceTextStyle(context)?.copyWith(
                              color: ColorTween(
                                begin: sysColors.onSurface,
                                end: sysColors.onPrimary,
                              ).transform(widget.animationController.value),
                            ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNonMobileHeader(BuildContext context) {
    final client = Matrix.of(context).client;
    final presence = client.presences[widget.user.id];

    return ValueListenableBuilder(
      valueListenable: widget.userInfoNotifier,
      builder: (context, userInfo, child) {
        final userInfoModel =
            userInfo.getSuccessOrNull<GetUserInfoSuccess>()?.userInfo;
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
            Text(
              userInfoModel?.displayName ?? widget.user.calcDisplayname(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: LinagoraTextStyle.material().bodyMedium2.copyWith(
                    color: LinagoraSysColors.material().onSurface,
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
          mxContent: widget.user.avatarUrl,
          name: userInfoModel?.displayName ?? widget.user.calcDisplayname(),
          size: 160,
        );
      },
      (success) {
        if (success is GettingUserInfo) {
          return const SizedBox(
            width: 160,
            height: 160,
            child: Center(
              child: CupertinoActivityIndicator(
                animating: true,
              ),
            ),
          );
        }
        if (success is GetUserInfoSuccess) {
          return Avatar(
            mxContent: userInfoModel?.avatarUrl != null
                ? Uri.parse(userInfoModel?.avatarUrl ?? '')
                : widget.user.avatarUrl,
            name: userInfoModel?.displayName ?? widget.user.calcDisplayname(),
            size: 160,
          );
        }
        return Avatar(
          mxContent: widget.user.avatarUrl,
          name: userInfoModel?.displayName ?? widget.user.calcDisplayname(),
          size: 160,
        );
      },
    );
  }
}
