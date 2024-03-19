import 'dart:async';

import 'package:dartz/dartz.dart' hide State;
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/domain/app_state/contact/lookup_match_contact_state.dart';
import 'package:fluffychat/domain/usecase/contacts/lookup_match_contact_interactor.dart';
import 'package:fluffychat/pages/profile_info/profile_info_body/profile_info_body_view.dart';
import 'package:fluffychat/presentation/model/presentation_contact_constant.dart';
import 'package:fluffychat/presentation/model/search/presentation_search.dart';
import 'package:fluffychat/utils/platform_infos.dart';
import 'package:fluffychat/widgets/matrix.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:matrix/matrix.dart';

class ProfileInfoBody extends StatefulWidget {
  const ProfileInfoBody({
    required this.user,
    this.onNewChatOpen,
    Key? key,
  }) : super(key: key);

  final User? user;

  final void Function()? onNewChatOpen;

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
        () => PlatformInfos.isMobile
            ? context.push(
                '/$path/draftChat',
                extra: {
                  PresentationContactConstant.receiverId:
                      contactPresentationSearch.matrixId ?? '',
                  PresentationContactConstant.email:
                      contactPresentationSearch.email ?? '',
                  PresentationContactConstant.displayName:
                      contactPresentationSearch.displayName ?? '',
                  PresentationContactConstant.status: '',
                },
              )
            : context.go(
                '/$path/draftChat',
                extra: {
                  PresentationContactConstant.receiverId:
                      contactPresentationSearch.matrixId ?? '',
                  PresentationContactConstant.email:
                      contactPresentationSearch.email ?? '',
                  PresentationContactConstant.displayName:
                      contactPresentationSearch.displayName ?? '',
                  PresentationContactConstant.status: '',
                },
              ),
      );
    }
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
