import 'package:collection/collection.dart';
import 'package:fluffychat/generated/l10n/app_localizations.dart';
import 'package:fluffychat/pages/contacts_tab/widgets/add_contact/add_contact_dialog.dart';
import 'package:fluffychat/pages/contacts_tab/widgets/add_contact/widgets/add_contact_info.dart';
import 'package:fluffychat/resource/image_paths.dart';
import 'package:flutter/material.dart';
import 'package:linagora_design_flutter/colors/linagora_ref_colors.dart';
import 'package:linagora_design_flutter/colors/linagora_sys_colors.dart';
import 'package:matrix/matrix.dart';

class AddContactDialogViewWeb extends StatelessWidget {
  const AddContactDialogViewWeb({super.key, required this.controller});

  final AddContactDialogController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context)!;
    final textTheme = Theme.of(context).textTheme;
    final sysColor = LinagoraSysColors.material();
    final refColor = LinagoraRefColors.material();

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 459),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Center(
                    child: Text(
                      l10n.newContact,
                      style: textTheme.headlineSmall?.copyWith(
                        fontSize: 24,
                        height: 32 / 24,
                        color: sysColor.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    padding: const EdgeInsets.all(12),
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(
                      Icons.close,
                      size: 24,
                      color: sysColor.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
            AddContactInfo(
              title: l10n.firstName,
              onChanged: (value) => controller.firstName = value,
              iconData: Icons.person_outline,
              initialValue: controller.firstName,
              autoFocus: true,
              textInputAction: TextInputAction.next,
            ),
            AddContactInfo(
              title: l10n.lastName,
              onChanged: (value) => controller.lastName = value,
              iconData: Icons.person_outline,
              textInputAction: TextInputAction.next,
            ),
            ValueListenableBuilder(
              valueListenable: controller.usernameErrorMessage,
              builder: (context, errorMessage, child) {
                return AddContactInfo(
                  title: l10n.matrixId,
                  initialValue: controller.userName.value,
                  onChanged: controller.onUsernameChanged,
                  assetPath: ImagePaths.icMatrixid,
                  errorMessage: errorMessage,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => controller.onSave(),
                  hintText: controller.matrixIdHintText,
                );
              },
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextButton(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        vertical: 14,
                        horizontal: 24,
                      ),
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(100)),
                      ),
                      textStyle: textTheme.labelLarge?.copyWith(
                        fontSize: 14,
                        height: 20 / 14,
                        color: sysColor.primary,
                      ),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: Text(l10n.cancel),
                  ),
                  const SizedBox(width: 16),
                  ValueListenableBuilder(
                    valueListenable: controller.userName,
                    builder: (context, userName, child) {
                      final existedContact = controller.availableContacts
                          .firstWhereOrNull(
                            (contact) => contact.matrixId == userName,
                          );

                      return TextButton(
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            vertical: 14,
                            horizontal: 24,
                          ),
                          backgroundColor: userName.isValidMatrixId
                              ? sysColor.primary
                              : refColor.neutral[70],
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.all(
                              Radius.circular(100),
                            ),
                          ),
                        ),
                        onPressed: controller.onSave,
                        child: Text(
                          existedContact != null ? l10n.sendMessage : l10n.save,
                          style: textTheme.labelLarge?.copyWith(
                            fontSize: 14,
                            height: 20 / 14,
                            color: sysColor.onPrimary,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
