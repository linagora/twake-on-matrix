import 'dart:async';

import 'package:dartz/dartz.dart' hide State;
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/domain/app_state/contact/lookup_match_contact_state.dart';
import 'package:fluffychat/domain/usecase/contacts/lookup_match_contact_interactor.dart';
import 'package:fluffychat/pages/profile_info/profile_info_body/profile_info_body_view.dart';
import 'package:fluffychat/pages/profile_info/profile_info_body/profile_info_body_view_style.dart';
import 'package:fluffychat/presentation/enum/profile_info/profile_info_body_enum.dart';
import 'package:fluffychat/presentation/model/contact/presentation_contact_constant.dart';
import 'package:fluffychat/presentation/model/search/presentation_search.dart';
import 'package:fluffychat/utils/dialog/twake_dialog.dart';
import 'package:fluffychat/utils/dialog/warning_dialog.dart';
import 'package:fluffychat/utils/platform_infos.dart';
import 'package:fluffychat/utils/twake_snackbar.dart';
import 'package:fluffychat/widgets/matrix.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:go_router/go_router.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';
import 'package:matrix/matrix.dart';

class ProfileInfoBody extends StatefulWidget {
  const ProfileInfoBody({
    required this.user,
    this.onNewChatOpen,
    this.onUpdatedMembers,
    super.key,
  });

  final User? user;

  final VoidCallback? onNewChatOpen;

  final VoidCallback? onUpdatedMembers;

  @override
  State<ProfileInfoBody> createState() => ProfileInfoBodyController();
}

class ProfileInfoBodyController extends State<ProfileInfoBody> {
  final _lookupMatchContactInteractor =
      getIt.get<LookupMatchContactInteractor>();

  StreamSubscription? lookupContactNotifierSub;

  final ValueNotifier<Either<Failure, Success>> lookupContactNotifier =
      ValueNotifier<Either<Failure, Success>>(
    const Right(LookupContactsInitial()),
  );

  User? get user => widget.user;

  bool get isOwnProfile => user?.id == user?.room.client.userID;

  void lookupMatchContactAction() {
    if (user == null) return;
    lookupContactNotifierSub = _lookupMatchContactInteractor
        .execute(
          val: user!.id,
        )
        .listen(
          (event) => lookupContactNotifier.value = event,
        );
  }

  void openNewChat() {
    if (user == null) return;
    final roomId = Matrix.of(context).client.getDirectChatFromUserId(user!.id);

    if (roomId == null) {
      if (!PlatformInfos.isMobile && widget.onNewChatOpen != null) {
        widget.onNewChatOpen!();
      }

      _goToDraftChat(
        context: context,
        path: "rooms",
        contactPresentationSearch: user!.toContactPresentationSearch(),
      );
    } else {
      if (PlatformInfos.isMobile) {
        Navigator.of(context)
            .popUntil((route) => route.settings.name == "/rooms/room");
      } else {
        if (widget.onNewChatOpen != null) widget.onNewChatOpen!();
      }

      context.go('/rooms/$roomId');
    }
  }

  void _goToDraftChat({
    required BuildContext context,
    required String path,
    required ContactPresentationSearch contactPresentationSearch,
  }) {
    if (contactPresentationSearch.matrixId !=
        Matrix.of(context).client.userID) {
      Router.neglect(
        context,
        () => context.go(
          '/$path/draftChat',
          extra: {
            PresentationContactConstant.receiverId:
                contactPresentationSearch.matrixId ?? '',
            PresentationContactConstant.displayName:
                contactPresentationSearch.displayName ?? '',
            PresentationContactConstant.status: '',
          },
        ),
      );
    }
  }

  Future<void> removeFromGroupChat() async {
    if (user == null) return;
    WarningDialog.showCancelable(
      context,
      message: L10n.of(context)!.removeReason(
        user?.displayName ?? '',
      ),
      title: L10n.of(context)!.removeUser,
      acceptText: L10n.of(context)!.remove,
      cancelText: L10n.of(context)!.cancel,
      acceptTextColor: LinagoraSysColors.material().error,
      onAccept: () async {
        WarningDialog.hideWarningDialog(context);
        final result = await TwakeDialog.showFutureLoadingDialogFullScreen(
          future: () => user!.kick(),
        );
        if (result.error != null) {
          TwakeSnackBar.show(
            context,
            result.error!.message,
          );
          return;
        }
        widget.onUpdatedMembers?.call();
      },
    );
  }

  List<ProfileInfoActions> profileInfoActions() {
    return [
      ProfileInfoActions.sendMessage,
      if (user!.canKick) ProfileInfoActions.removeFromGroup,
    ];
  }

  void handleActions(ProfileInfoActions action) {
    switch (action) {
      case ProfileInfoActions.sendMessage:
        openNewChat();
        break;
      case ProfileInfoActions.removeFromGroup:
        removeFromGroupChat();
        break;
      default:
        break;
    }
  }

  Widget buildProfileInfoActions(BuildContext context) {
    return Column(
      children: [
        Divider(
          thickness: ProfileInfoBodyViewStyle.bigDividerThickness,
          color: LinagoraStateLayer(
            LinagoraSysColors.material().surfaceTint,
          ).opacityLayer3,
        ),
        Column(
          children: profileInfoActions().map((action) {
            return Column(
              children: [
                if (action.divider(context) != null) action.divider(context)!,
                TwakeInkWell(
                  onTap: () => handleActions(action),
                  child: Padding(
                    padding: action.padding(context),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 10,
                            horizontal: 60,
                          ),
                          height: ProfileInfoBodyViewStyle.actionHeight,
                          decoration: action.decoration(context),
                          child: Row(
                            children: [
                              if (action.icon() != null)
                                Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: action.icon()!,
                                ),
                              Text(
                                action.label(context),
                                style: action.textStyle(context),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }

  @override
  void initState() {
    lookupMatchContactAction();
    super.initState();
  }

  @override
  void dispose() {
    lookupContactNotifier.dispose();
    lookupContactNotifierSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ProfileInfoBodyView(controller: this);
}
