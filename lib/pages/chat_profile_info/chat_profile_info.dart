import 'package:dartz/dartz.dart' hide State;
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/domain/app_state/contact/lookup_match_contact_state.dart';
import 'package:fluffychat/domain/usecase/contacts/lookup_match_contact_interactor.dart';
import 'package:fluffychat/pages/chat_profile_info/chat_profile_info_navigator.dart';
import 'package:fluffychat/pages/chat_profile_info/chat_profile_info_view.dart';
import 'package:fluffychat/presentation/model/presentation_contact.dart';
import 'package:fluffychat/widgets/matrix.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';

class ProfileInfo extends StatefulWidget {
  final VoidCallback? onBack;
  final String? roomId;
  final PresentationContact? contact;
  final bool isInStack;

  const ProfileInfo({
    super.key,
    required this.onBack,
    required this.isInStack,
    this.roomId,
    this.contact,
  });

  @override
  State<ProfileInfo> createState() => ProfileInfoController();
}

class ProfileInfoController extends State<ProfileInfo> {
  final _lookupMatchContactInteractor =
      getIt.get<LookupMatchContactInteractor>();

  final ValueNotifier<Either<Failure, Success>> lookupContactNotifier =
      ValueNotifier<Either<Failure, Success>>(
    const Right(LookupContactsInitial()),
  );

  Room? get room => widget.roomId != null
      ? Matrix.of(context).client.getRoomById(widget.roomId!)
      : null;

  User? get user =>
      room?.unsafeGetUserFromMemoryOrFallback(room?.directChatMatrixID ?? '');

  void lookupMatchContactAction() {
    _lookupMatchContactInteractor
        .execute(
          val: user?.id ?? '',
        )
        .listen(
          (event) => lookupContactNotifier.value = event,
        );
  }

  void goToProfileShared() {
    Navigator.of(context).pushNamed(
      ProfileInfoRoutes.profileInfoShared,
      arguments: widget.roomId,
    );
  }

  @override
  void initState() {
    lookupMatchContactAction();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return ProfileInfoView(this);
  }
}
