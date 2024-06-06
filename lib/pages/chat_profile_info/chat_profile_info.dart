import 'dart:async';

import 'package:dartz/dartz.dart' hide State;
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/domain/app_state/contact/lookup_match_contact_state.dart';
import 'package:fluffychat/domain/usecase/contacts/lookup_match_contact_interactor.dart';
import 'package:fluffychat/pages/chat_profile_info/chat_profile_info_view.dart';
import 'package:fluffychat/presentation/mixins/chat_details_tab_mixin.dart';
import 'package:fluffychat/presentation/mixins/handle_video_download_mixin.dart';
import 'package:fluffychat/presentation/mixins/play_video_action_mixin.dart';
import 'package:fluffychat/presentation/model/contact/presentation_contact.dart';
import 'package:fluffychat/widgets/matrix.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';

class ChatProfileInfo extends StatefulWidget {
  final VoidCallback? onBack;
  final String? roomId;
  final PresentationContact? contact;
  final bool isInStack;
  final bool isDraftInfo;

  const ChatProfileInfo({
    super.key,
    required this.onBack,
    required this.isInStack,
    this.roomId,
    this.contact,
    required this.isDraftInfo,
  });

  @override
  State<ChatProfileInfo> createState() => ChatProfileInfoController();
}

class ChatProfileInfoController extends State<ChatProfileInfo>
    with
        HandleVideoDownloadMixin,
        PlayVideoActionMixin,
        SingleTickerProviderStateMixin,
        ChatDetailsTabMixin {
  final _lookupMatchContactInteractor =
      getIt.get<LookupMatchContactInteractor>();

  StreamSubscription? lookupContactNotifierSub;

  final ValueNotifier<Either<Failure, Success>> lookupContactNotifier =
      ValueNotifier<Either<Failure, Success>>(
    const Right(LookupContactsInitial()),
  );

  final GlobalKey<NestedScrollViewState> nestedScrollViewState = GlobalKey();

  Room? get room => widget.roomId != null
      ? Matrix.of(context).client.getRoomById(widget.roomId!)
      : null;

  User? get user =>
      room?.unsafeGetUserFromMemoryOrFallback(room?.directChatMatrixID ?? '');

  void lookupMatchContactAction() {
    lookupContactNotifierSub = _lookupMatchContactInteractor
        .execute(
          val: widget.contact?.matrixId ?? user?.id ?? '',
        )
        .listen(
          (event) => lookupContactNotifier.value = event,
        );
  }

  Future<String> _handleDownloadAndPlayVideo(Event event) {
    return handleDownloadVideoEvent(
      event: event,
      playVideoAction: (path) => playVideoAction(
        context,
        path,
        event: event,
      ),
    );
  }

  List<Widget> getTabViewChildren() {
    return profileSharedPages(_handleDownloadAndPlayVideo).map((page) {
      return page.child;
    }).toList();
  }

  @override
  void initState() {
    lookupMatchContactAction();
    initSharedMediaControllers(room!, this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      nestedScrollViewState.currentState?.innerController.addListener(
        () => listenerInnerController(nestedScrollViewState),
      );
      refreshDataInTabViewInit();
    });
    super.initState();
  }

  @override
  void dispose() {
    disposeSharedMediaControllers();
    nestedScrollViewState.currentState?.innerController.dispose();
    lookupContactNotifier.dispose();
    lookupContactNotifierSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChatProfileInfoView(this);
  }
}
