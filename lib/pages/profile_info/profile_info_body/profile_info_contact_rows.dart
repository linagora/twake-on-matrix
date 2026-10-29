import 'package:flutter_riverpod/flutter_riverpod.dart' show AsyncValue;
import 'package:twake_chat/domain/model/user_info/user_info.dart';
import 'package:twake_chat/pages/profile_info/copiable_profile_row/icon_copiable_profile_row.dart';
import 'package:twake_chat/pages/profile_info/copiable_profile_row/svg_copiable_profile_row.dart';
import 'package:twake_chat/generated/assets.gen.dart';
import 'package:flutter/material.dart';

import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';
import 'package:matrix/matrix.dart';

class ProfileInfoContactRows extends StatelessWidget {
  const ProfileInfoContactRows({
    required this.user,
    required this.userInfo,
    super.key,
  });

  final User user;
  final AsyncValue<UserInfo> userInfo;

  @override
  Widget build(BuildContext context) {
    final userInfoModel = userInfo.value;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(
          color: LinagoraRefColors.material().neutral[90] ?? Colors.black,
        ),
        borderRadius: BorderRadius.circular(16),
        color: LinagoraSysColors.material().onPrimary,
      ),
      child: AnimatedSize(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        child: SizedBox(
          width: double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              SvgCopiableProfileRow(
                leadingIconPath: Assets.images.icMatrixid.path,
                caption: L10n.of(context)!.matrixId,
                copiableText: user.id,
                enableDividerTop:
                    userInfoModel != null &&
                    (userInfoModel.phones?.firstOrNull != null ||
                        userInfoModel.emails?.firstOrNull != null),
              ),
              if (userInfoModel?.phones?.firstOrNull != null)
                IconCopiableProfileRow(
                  icon: Icons.call,
                  caption: L10n.of(context)!.phone,
                  copiableText: userInfoModel!.phones!.firstOrNull ?? '',
                  enableDividerTop: userInfoModel.emails?.firstOrNull != null,
                ),
              if (userInfoModel?.emails?.firstOrNull != null)
                IconCopiableProfileRow(
                  icon: Icons.alternate_email,
                  caption: L10n.of(context)!.email,
                  copiableText: userInfoModel!.emails!.firstOrNull ?? '',
                ),
            ],
          ),
        ),
      ),
    );
  }
}
