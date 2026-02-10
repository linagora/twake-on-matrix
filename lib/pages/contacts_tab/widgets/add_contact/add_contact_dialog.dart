import 'package:collection/collection.dart';
import 'package:dartz/dartz.dart' hide State;
import 'package:debounce_throttle/debounce_throttle.dart';
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/data/model/addressbook/address_book.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/domain/app_state/contact/get_contacts_state.dart';
import 'package:fluffychat/domain/app_state/contact/post_address_book_state.dart';
import 'package:fluffychat/domain/contact_manager/contacts_manager.dart';
import 'package:fluffychat/domain/model/extensions/contact/address_book_extension.dart';
import 'package:fluffychat/domain/usecase/contacts/post_address_book_interactor.dart';
import 'package:fluffychat/generated/l10n/app_localizations.dart';
import 'package:fluffychat/pages/chat_profile_info/chat_profile_info_navigator.dart';
import 'package:fluffychat/pages/contacts_tab/widgets/add_contact/add_contact_dialog_view.dart';
import 'package:fluffychat/pages/contacts_tab/widgets/add_contact/add_contact_dialog_view_web.dart';
import 'package:fluffychat/presentation/extensions/contact/presentation_contact_extension.dart';
import 'package:fluffychat/presentation/model/contact/presentation_contact.dart';
import 'package:fluffychat/presentation/model/contact/presentation_contact_constant.dart';
import 'package:fluffychat/utils/dialog/twake_dialog.dart';
import 'package:fluffychat/utils/platform_infos.dart';
import 'package:fluffychat/utils/twake_snackbar.dart';
import 'package:fluffychat/widgets/matrix.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:linagora_design_flutter/colors/linagora_sys_colors.dart';
import 'package:matrix/matrix.dart';

Future<void> showAddContactDialog(
  BuildContext context, {
  String? displayName,
  String? matrixId,
}) {
  if (PlatformInfos.isMobile) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: LinagoraSysColors.material().onPrimary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      useSafeArea: true,
      scrollControlDisabledMaxHeightRatio: 0.8,
      builder: (context) {
        return AddContactDialog(displayName: displayName, matrixId: matrixId);
      },
    );
  }

  return showDialog(
    context: context,
    builder: (context) {
      return Dialog(
        backgroundColor: LinagoraSysColors.material().onPrimary,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
        insetPadding: const EdgeInsets.all(16),
        child: AddContactDialog(displayName: displayName, matrixId: matrixId),
      );
    },
  );
}

class AddContactDialog extends StatefulWidget {
  const AddContactDialog({super.key, this.displayName, this.matrixId});

  final String? displayName;
  final String? matrixId;

  @override
  State<AddContactDialog> createState() => AddContactDialogController();
}

class AddContactDialogController extends State<AddContactDialog> {
  String firstName = '';
  String lastName = '';
  final matrixIdHintText = '@example:twake.app';
  late final ValueNotifier<String> userName;
  final usernameErrorMessage = ValueNotifier<String?>(null);
  late final validateUsernameDebouncer = Debouncer<String?>(
    const Duration(milliseconds: 1200),
    initialValue: null,
    onChanged: (value) {
      if (value?.isValidMatrixId == true || value?.isEmpty == true) {
        usernameErrorMessage.value = null;
      } else {
        usernameErrorMessage.value = L10n.of(context)!.invalidUsername;
      }
    },
  );

  List<PresentationContact> get availableContacts =>
      getIt
          .get<ContactsManager>()
          .getContactsNotifier()
          .value
          .getSuccessOrNull<GetContactsSuccess>()
          ?.contacts
          .expand((contact) => contact.toPresentationContacts())
          .toList() ??
      [];

  void onUsernameChanged(String value) {
    userName.value = value;
    usernameErrorMessage.value = null;
    validateUsernameDebouncer.value = value;
  }

  Future<void> onSave() async {
    if (!userName.value.isValidMatrixId) return;

    final existedContact = availableContacts.firstWhereOrNull(
      (contact) => contact.matrixId == userName.value,
    );

    if (existedContact == null) {
      final result =
          await TwakeDialog.showFutureLoadingDialogFullScreen<
            Either<Failure, Success>
          >(
            future: () => getIt
                .get<PostAddressBookInteractor>()
                .execute(
                  addressBooks: [
                    AddressBook(
                      mxid: userName.value,
                      displayName: '$firstName $lastName',
                    ),
                  ],
                )
                .last,
          );
      final state = result.result?.fold(
        (failure) => failure,
        (success) => success,
      );
      if (state is PostAddressBookFailureState) {
        TwakeSnackBar.show(context, state.exception.toString());
        return;
      } else if (state is PostAddressBookSuccessState) {
        getIt.get<ContactsManager>().refreshTomContacts(
          Matrix.of(context).client,
        );
        final createdContact = state.updatedAddressBooks.firstOrNull
            ?.toPresentationContact()
            .firstOrNull;
        if (PlatformInfos.isMobile) {
          Navigator.pop(context);
          Navigator.of(context).push(
            CupertinoPageRoute(
              builder: (context) => ChatProfileInfoNavigator(
                isInStack: true,
                onBack: context.pop,
                contact: createdContact,
              ),
            ),
          );
        } else {
          chatWithUser(userName.value, contact: createdContact);
        }
      }
      return;
    }

    chatWithUser(userName.value, contact: existedContact);
  }

  void chatWithUser(String matrixId, {PresentationContact? contact}) {
    final existedRoomId = Matrix.of(
      context,
    ).client.getDirectChatFromUserId(matrixId);

    Navigator.pop(context);

    if (existedRoomId != null) {
      return context.go('/rooms/$existedRoomId');
    }

    Router.neglect(
      context,
      () => context.go(
        '/rooms/draftChat',
        extra: {
          PresentationContactConstant.receiverId: contact?.matrixId ?? '',
          PresentationContactConstant.displayName: contact?.displayName ?? '',
          PresentationContactConstant.status: '',
        },
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    firstName = widget.displayName ?? '';

    userName = ValueNotifier(widget.matrixId ?? '');
  }

  @override
  void dispose() {
    userName.dispose();
    usernameErrorMessage.dispose();
    validateUsernameDebouncer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PlatformInfos.isMobile
        ? AddContactDialogView(controller: this)
        : AddContactDialogViewWeb(controller: this);
  }
}
