import 'package:dartz/dartz.dart' hide State;
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/domain/app_state/user_info/get_user_info_state.dart';
import 'package:fluffychat/pages/profile_info/copiable_profile_row/icon_copiable_profile_row.dart';
import 'package:fluffychat/pages/profile_info/copiable_profile_row/svg_copiable_profile_row.dart';
import 'package:fluffychat/resource/image_paths.dart';
import 'package:flutter/material.dart';

import 'package:fluffychat/generated/l10n/app_localizations.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';
import 'package:matrix/matrix.dart';

class ProfileInfoContactRows extends StatelessWidget {
  const ProfileInfoContactRows({
    required this.user,
    required this.userInfoNotifier,
    super.key,
  });

  final User user;
  final ValueNotifier<Either<Failure, Success>> userInfoNotifier;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(
          color: LinagoraRefColors.material().neutral[90] ?? Colors.black,
        ),
        borderRadius: BorderRadius.circular(16),
        color: LinagoraSysColors.material().onPrimary,
      ),
      child: ValueListenableBuilder(
        valueListenable: userInfoNotifier,
        builder: (context, userInfo, child) {
          final userInfoModel =
              userInfo.getSuccessOrNull<GetUserInfoSuccess>()?.userInfo;
          final isLoading = userInfo is GettingUserInfo;

          return AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: SizedBox(
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  SvgCopiableProfileRow(
                    leadingIconPath: ImagePaths.icMatrixid,
                    caption: L10n.of(context)!.matrixId,
                    copiableText: user.id,
                    enableDividerTop: userInfoModel != null &&
                        (userInfoModel.phones?.firstOrNull != null ||
                            userInfoModel.emails?.firstOrNull != null),
                  ),
                  if (isLoading)
                    _LoadingPlaceholder()
                  else ...[
                    if (userInfoModel?.phones?.firstOrNull != null)
                      IconCopiableProfileRow(
                        icon: Icons.call,
                        caption: L10n.of(context)!.phone,
                        copiableText: userInfoModel!.phones!.firstOrNull ?? '',
                        enableDividerTop:
                            userInfoModel.emails?.firstOrNull != null,
                      ),
                    if (userInfoModel?.emails?.firstOrNull != null)
                      IconCopiableProfileRow(
                        icon: Icons.alternate_email,
                        caption: L10n.of(context)!.email,
                        copiableText: userInfoModel!.emails!.firstOrNull ?? '',
                      ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _LoadingPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        children: [
          _ShimmerRow(),
          const SizedBox(height: 8),
          _ShimmerRow(),
        ],
      ),
    );
  }
}

class _ShimmerRow extends StatefulWidget {
  @override
  State<_ShimmerRow> createState() => _ShimmerRowState();
}

class _ShimmerRowState extends State<_ShimmerRow>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          height: 48,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                Colors.grey.shade300,
                Colors.grey.shade100,
                Colors.grey.shade300,
              ],
              stops: [
                _controller.value - 0.3,
                _controller.value,
                _controller.value + 0.3,
              ].map((e) => e.clamp(0.0, 1.0)).toList(),
            ),
            borderRadius: BorderRadius.circular(8),
          ),
        );
      },
    );
  }
}
