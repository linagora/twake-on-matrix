import 'package:fluffychat/domain/app_state/contact/lookup_match_contact_state.dart';
import 'package:fluffychat/pages/profile_info/copiable_profile_row/icon_copiable_profile_row.dart';
import 'package:fluffychat/pages/profile_info/copiable_profile_row/svg_copiable_profile_row.dart';
import 'package:fluffychat/pages/profile_info/profile_info_body/profile_info_body.dart';
import 'package:fluffychat/pages/profile_info/profile_info_body/profile_info_body_view_style.dart';
import 'package:fluffychat/resource/image_paths.dart';
import 'package:fluffychat/utils/dialog/twake_dialog.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions/presence_extension.dart';
import 'package:fluffychat/widgets/avatar/avatar.dart';
import 'package:fluffychat/widgets/matrix.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:linagora_design_flutter/colors/linagora_sys_colors.dart';
import 'package:matrix/matrix.dart';

class ProfileInfoBodyView extends StatelessWidget {
  const ProfileInfoBodyView({
    required this.controller,
    Key? key,
  }) : super(key: key);
  final ProfileInfoBodyController controller;

  @override
  Widget build(BuildContext context) {
    if (controller.user == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: ProfileInfoBodyViewStyle.profileInformationsTopPadding,
          child: Column(
            children: [
              _ProfileInfoHeader(controller.user!),
              _ProfileInfoContactRows(
                user: controller.user!,
                lookupContactNotifier: controller.lookupContactNotifier,
              ),
            ],
          ),
        ),
        if (!controller.isOwnProfile) ...[
          Divider(
            thickness: ProfileInfoBodyViewStyle.bigDividerThickness,
            color: LinagoraSysColors.material().surface,
          ),
          Padding(
            padding: ProfileInfoBodyViewStyle.newChatButtonPadding,
            child: Row(
              children: [
                Expanded(
                  child: TextButton.icon(
                    onPressed: () async {
                      final roomIdResult =
                          await TwakeDialog.showFutureLoadingDialogFullScreen(
                        future: () => controller.user!.startDirectChat(),
                      );
                      if (roomIdResult.error != null) return;

                      controller.openNewChat(roomIdResult.result!);
                    },
                    icon: const Icon(Icons.chat_outlined),
                    label: L10n.of(context)?.newChat != null
                        ? Row(
                            children: [
                              Expanded(
                                child: Text(
                                  L10n.of(context)!.sendMessage,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          )
                        : const SizedBox.shrink(),
                  ),
                ),
              ],
            ),
          ),
        ] else
          const SizedBox(height: 16),
      ],
    );
  }
}

class _ProfileInfoHeader extends StatelessWidget {
  const _ProfileInfoHeader(this.user, {Key? key}) : super(key: key);
  final User user;

  @override
  Widget build(BuildContext context) {
    final client = Matrix.of(context).client;
    final presence = client.presences[user.id];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: ProfileInfoBodyViewStyle.avatarPadding,
          child: Avatar(
            mxContent: user.avatarUrl,
            name: user.calcDisplayname(),
          ),
        ),
        Text(
          user.calcDisplayname(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
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
  }
}

class _ProfileInfoContactRows extends StatelessWidget {
  const _ProfileInfoContactRows({
    required this.user,
    required this.lookupContactNotifier,
    Key? key,
  }) : super(key: key);
  final User user;
  final ValueListenable lookupContactNotifier;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 16),
        SvgCopiableProfileRow(
          leadingIconPath: ImagePaths.icMatrixid,
          caption: L10n.of(context)!.matrixId,
          copiableText: user.id,
        ),
        ValueListenableBuilder(
          valueListenable: lookupContactNotifier,
          // valueListenable: controller.lookupContactNotifier,
          builder: (context, contact, child) {
            return contact.fold(
              (failure) => const SizedBox.shrink(),
              (success) {
                if (success is LookupMatchContactSuccess) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (success.contact.email != null)
                        IconCopiableProfileRow(
                          icon: Icons.alternate_email,
                          caption: L10n.of(context)!.email,
                          copiableText: success.contact.email!,
                        ),
                      if (success.contact.phoneNumber != null)
                        IconCopiableProfileRow(
                          icon: Icons.call,
                          caption: L10n.of(context)!.phone,
                          copiableText: success.contact.phoneNumber!,
                        ),
                    ],
                  );
                }
                return const SizedBox.shrink();
              },
            );
          },
        ),
      ],
    );
  }
}
