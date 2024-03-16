import 'dart:async';

import 'package:dartz/dartz.dart' hide State;
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/domain/app_state/contact/lookup_match_contact_state.dart';
import 'package:fluffychat/domain/usecase/contacts/lookup_match_contact_interactor.dart';
import 'package:fluffychat/pages/profile_info/profile_info_body/profile_info_body_view.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:matrix/matrix.dart';

class ProfileInfoBody extends StatefulWidget {
  const ProfileInfoBody({
    required this.user,
    required this.parentContext,
    this.onNewChatOpen,
    Key? key,
  }) : super(key: key);

  final User? user;

  final BuildContext parentContext;

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

  BuildContext get parentContext => widget.parentContext;

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

  void openNewChat(String roomId) {
    parentContext.go('/rooms/$roomId');
    if (widget.onNewChatOpen != null) widget.onNewChatOpen!();
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
