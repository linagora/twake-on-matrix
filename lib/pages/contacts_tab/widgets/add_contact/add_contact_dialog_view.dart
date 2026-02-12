import 'package:collection/collection.dart';
import 'package:fluffychat/generated/l10n/app_localizations.dart';
import 'package:fluffychat/pages/contacts_tab/widgets/add_contact/add_contact_dialog.dart';
import 'package:fluffychat/pages/contacts_tab/widgets/add_contact/widgets/add_contact_info.dart';
import 'package:fluffychat/resource/image_paths.dart';
import 'package:flutter/material.dart';
import 'package:linagora_design_flutter/colors/linagora_ref_colors.dart';
import 'package:linagora_design_flutter/colors/linagora_sys_colors.dart';
import 'package:matrix/matrix.dart';

class AddContactDialogView extends StatelessWidget {
  const AddContactDialogView({super.key, required this.controller});

  final AddContactDialogController controller;

  @override
  Widget build(BuildContext context) {
    final sysColor = LinagoraSysColors.material();
    final refColor = LinagoraRefColors.material();
    final textTheme = Theme.of(context).textTheme;
    final l10n = L10n.of(context)!;
    final saveButton = ValueListenableBuilder(
      valueListenable: controller.userName,
      builder: (context, userName, child) {
        final existedContact = controller.availableContacts.firstWhereOrNull(
          (contact) => contact.matrixId == userName,
        );

        return TextButton(
          onPressed: controller.onSave,
          child: Text(
            existedContact != null ? l10n.sendMessage : l10n.save,
            style: textTheme.labelLarge?.copyWith(
              fontSize: 14,
              height: 20 / 14,
              color: userName.isValidMatrixId
                  ? sysColor.primary
                  : refColor.neutral[70],
            ),
          ),
        );
      },
    );
    final cancelButton = TextButton(
      onPressed: () => Navigator.pop(context),
      child: Text(
        l10n.cancel,
        style: textTheme.labelLarge?.copyWith(
          fontSize: 14,
          height: 20 / 14,
          color: sysColor.primary,
        ),
      ),
    );
    final title = Text(
      l10n.newContact,
      style: textTheme.bodyLarge?.copyWith(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        height: 24 / 17,
      ),
      textAlign: TextAlign.center,
    );

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 14),
          Row(
            children: [
              Stack(
                alignment: Alignment.centerLeft,
                children: [
                  IgnorePointer(child: Opacity(opacity: 0, child: saveButton)),
                  cancelButton,
                ],
              ),
              Expanded(child: title),
              Stack(
                alignment: Alignment.centerRight,
                children: [
                  IgnorePointer(
                    child: Opacity(opacity: 0, child: cancelButton),
                  ),
                  saveButton,
                ],
              ),
            ],
          ),
          AddContactInfo(
            title: l10n.firstName,
            onChanged: (value) => controller.firstName = value,
            iconData: Icons.person_outline,
            additionalHorizontalPadding: 20,
            initialValue: controller.firstName,
            autoFocus: true,
            textInputAction: TextInputAction.next,
          ),
          AddContactInfo(
            title: l10n.lastName,
            onChanged: (value) => controller.lastName = value,
            iconData: Icons.person_outline,
            additionalHorizontalPadding: 20,
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
                additionalHorizontalPadding: 20,
                errorMessage: errorMessage,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => controller.onSave(),
                hintText: controller.matrixIdHintText,
              );
            },
          ),
          SizedBox(height: 30 + MediaQuery.viewInsetsOf(context).bottom),
        ],
      ),
    );
  }
}
