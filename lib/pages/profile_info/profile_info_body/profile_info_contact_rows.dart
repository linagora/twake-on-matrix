import 'package:fluffychat/domain/app_state/contact/lookup_match_contact_state.dart';
import 'package:fluffychat/pages/profile_info/copiable_profile_row/icon_copiable_profile_row.dart';
import 'package:fluffychat/pages/profile_info/copiable_profile_row/svg_copiable_profile_row.dart';
import 'package:fluffychat/resource/image_paths.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:matrix/matrix.dart';

class ProfileInfoContactRows extends StatelessWidget {
  const ProfileInfoContactRows({
    required this.user,
    required this.lookupContactNotifier,
    super.key,
  });
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
