import 'package:fluffychat/presentation/model/contact/presentation_contact_constant.dart';
import 'package:fluffychat/presentation/model/search/presentation_search.dart';
import 'package:fluffychat/utils/dialog/twake_dialog.dart';
import 'package:fluffychat/widgets/matrix.dart';
import 'package:flutter/material.dart';

import 'package:go_router/go_router.dart';
import 'package:matrix/matrix.dart';

mixin GoToDraftChatMixin {
  void onSearchItemTap({
    required BuildContext context,
    required String path,
    required PresentationSearch presentationSearch,
  }) async {
    if (presentationSearch is ContactPresentationSearch) {
      onContactTap(
        context: context,
        path: path,
        contactPresentationSearch: presentationSearch,
      );
    } else if (presentationSearch is RecentChatPresentationSearch) {
      onRecentChatTap(
        context: context,
        path: path,
        recentChatPresentationSearch: presentationSearch,
      );
    }
  }

  void onContactTap({
    required BuildContext context,
    required String path,
    required ContactPresentationSearch contactPresentationSearch,
  }) {
    final roomId = Matrix.of(context)
        .client
        .getDirectChatFromUserId(contactPresentationSearch.matrixId!);
    if (roomId == null) {
      goToDraftChat(
        context: context,
        path: path,
        contactPresentationSearch: contactPresentationSearch,
      );
    } else {
      TwakeDialog.showFutureLoadingDialogFullScreen(
        future: () async {
          if (contactPresentationSearch.matrixId != null &&
              contactPresentationSearch.matrixId!.isNotEmpty) {
            context.go('/$path/$roomId');
          }
        },
      );
    }
  }

  void onRecentChatTap({
    required BuildContext context,
    required String path,
    required RecentChatPresentationSearch recentChatPresentationSearch,
  }) {
    Logs().d(
      'GoToDraftChatMixin::onRecentChatTap() - MatrixID: ${recentChatPresentationSearch.id}',
    );
    context.go('/$path/${recentChatPresentationSearch.id}');
  }

  void goToDraftChat({
    required BuildContext context,
    required String path,
    required ContactPresentationSearch contactPresentationSearch,
  }) {
    if (contactPresentationSearch.matrixId !=
        Matrix.of(context).client.userID) {
      Router.neglect(
        context,
        () => context.push(
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

  void goToChatScreenFormRecentChat({
    required BuildContext context,
    required String path,
    required User user,
  }) async {
    Logs()
        .d('SearchController::getContactAndRecentChatStream() - event: $user');
    final roomIdResult = await TwakeDialog.showFutureLoadingDialogFullScreen(
      future: () => user.startDirectChat(),
    );
    if (roomIdResult.error != null) return;
    context.go('/$path/${roomIdResult.result!}');
  }
}
