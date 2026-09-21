import 'package:twake_chat/data/contact/datasources/matrix_profile_datasource.dart';
import 'package:twake_chat/pages/contacts_tab/providers/matrix_profile_providers.dart';
import 'package:twake_chat/pages/contacts_tab/providers/unified_contact_read_providers.dart';
import 'package:twake_chat/presentation/model/contact/presentation_contact.dart';
import 'package:twake_chat/widgets/avatar/avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linagora_design_flutter/colors/linagora_ref_colors.dart';

class AvatarWithBottomIconWidget extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final matrixId = presentationContact.matrixId;
    final unifiedAvatar = matrixId == null
        ? null
        : ref.watch(unifiedContactProvider(matrixId))?.avatarUrl;

    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(shape: BoxShape.circle),
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          if (matrixId != null && unifiedAvatar == null)
            FutureBuilder<MatrixUserProfile?>(
              future: ProviderScope.containerOf(
                context,
                listen: false,
              ).read(matrixUserProfileProvider(matrixId).future),
              builder: ((context, snapshot) {
                final avatarUrl = snapshot.data?.avatarUrl;
                return Avatar(
                  mxContent: avatarUrl == null ? null : Uri.tryParse(avatarUrl),
                  name: presentationContact.displayName,
                );
              }),
            ),
          if (matrixId == null) Avatar(name: presentationContact.displayName),
          if (matrixId != null && unifiedAvatar != null)
            Avatar(
              mxContent: Uri.tryParse(unifiedAvatar),
              name: presentationContact.displayName,
            ),
          Container(
            height: 20,
            width: 20,
            decoration: BoxDecoration(
              border: Border.all(width: 2, color: Colors.white),
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
