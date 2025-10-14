import 'package:collection/collection.dart';
import 'package:dartz/dartz.dart';
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/data/model/addressbook/address_book.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/domain/app_state/contact/post_address_book_state.dart';
import 'package:fluffychat/domain/contact_manager/contacts_manager.dart';
import 'package:fluffychat/domain/model/extensions/contact/address_book_extension.dart';
import 'package:fluffychat/domain/usecase/contacts/post_address_book_interactor.dart';
import 'package:fluffychat/generated/l10n/app_localizations.dart';
import 'package:fluffychat/pages/chat_profile_info/chat_profile_info_navigator.dart';
import 'package:fluffychat/pages/contacts_tab/widgets/add_contact/add_contact_dialog.dart';
import 'package:fluffychat/pages/contacts_tab/widgets/add_contact/widgets/add_contact_info.dart';
import 'package:fluffychat/presentation/model/contact/presentation_contact_constant.dart';
import 'package:fluffychat/resource/image_paths.dart';
import 'package:fluffychat/utils/dialog/twake_dialog.dart';
import 'package:fluffychat/utils/twake_snackbar.dart';
import 'package:fluffychat/widgets/matrix.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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
          onPressed: () async {
            if (!userName.isValidMatrixId) return;

            if (existedContact == null) {
              final result = await TwakeDialog
                  .showFutureLoadingDialogFullScreen<Either<Failure, Success>>(
                future: () => getIt.get<PostAddressBookInteractor>().execute(
                  addressBooks: [
                    AddressBook(
                      mxid: userName,
                      displayName:
                          '${controller.firstName} ${controller.lastName}',
                    ),
                  ],
                ).last,
              );
              final state = result.result?.fold(
                (failure) => failure,
                (success) => success,
              );
              if (state is PostAddressBookFailureState) {
                TwakeSnackBar.show(
                  context,
                  state.exception.toString(),
                );
                return;
              } else if (state is PostAddressBookSuccessState) {
                getIt.get<ContactsManager>().refreshTomContacts();
                context.pop();
                Navigator.of(context).push(
                  CupertinoPageRoute(
                    builder: (context) => ChatProfileInfoNavigator(
                      isInStack: true,
                      onBack: context.pop,
                      contact: state.updatedAddressBooks.firstOrNull
                          ?.toPresentationContact()
                          .firstOrNull,
                    ),
                  ),
                );
              }
              return;
            }

            final existedRoomId =
                Matrix.of(context).client.getDirectChatFromUserId(userName);
            if (existedRoomId != null) {
              context.pop();
              context.go('/rooms/$existedRoomId');
              return;
            }

            context.pop();
            Router.neglect(
              context,
              () => context.go(
                '/rooms/draftChat',
                extra: {
                  PresentationContactConstant.receiverId: existedContact.id,
                  PresentationContactConstant.displayName:
                      existedContact.displayName ?? '',
                  PresentationContactConstant.status: '',
                },
              ),
            );
          },
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
                  IgnorePointer(
                    child: Opacity(opacity: 0, child: saveButton),
                  ),
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
          ),
          AddContactInfo(
            title: l10n.lastName,
            onChanged: (value) => controller.lastName = value,
            iconData: Icons.person_outline,
            additionalHorizontalPadding: 20,
          ),
          AddContactInfo(
            title: l10n.username,
            initialValue: controller.userName.value,
            onChanged: (value) {
              controller.userName.value = value;
            },
            assetPath: ImagePaths.icMatrixid,
          ),
          SizedBox(height: 30 + MediaQuery.viewInsetsOf(context).bottom),
        ],
      ),
    );
  }
}
