import 'package:fluffychat/config/first_column_inner_routes.dart';
import 'package:fluffychat/pages/chat/encrypted_draft_chat_dialog.dart';
import 'package:fluffychat/presentation/model/draft_chat_constant.dart';
import 'package:fluffychat/presentation/model/presentation_contact_constant.dart';
import 'package:fluffychat/presentation/model/search/presentation_search.dart';
import 'package:fluffychat/utils/dialog/twake_dialog.dart';
import 'package:fluffychat/utils/extension/build_context_extension.dart';
import 'package:fluffychat/widgets/matrix.dart';
import 'package:fluffychat/widgets/twake_app.dart';
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
    bool enabledEncryption = true,
  }) {
    final roomId = Matrix.of(context)
        .client
        .getDirectChatFromUserId(contactPresentationSearch.matrixId!);
    if (roomId == null) {
      goToDraftChat(
        context: context,
        path: path,
        contactPresentationSearch: contactPresentationSearch,
        enableEncryption: enabledEncryption,
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
    bool enableEncryption = true,
  }) {
    if (contactPresentationSearch.matrixId !=
        Matrix.of(context).client.userID) {
      Router.neglect(
        context,
        () => context.push(
          '/$path/draftChat',
          extra: {
            DraftChatConstant.enableEncryption: enableEncryption,
            PresentationContactConstant.contact: {
              PresentationContactConstant.receiverId:
                  contactPresentationSearch.matrixId ?? '',
              PresentationContactConstant.email:
                  contactPresentationSearch.email ?? '',
              PresentationContactConstant.displayName:
                  contactPresentationSearch.displayName ?? '',
              PresentationContactConstant.status: '',
            },
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

  void goToNewPrivateChat(
    BuildContext context, {
    bool enableEncryption = true,
  }) async {
    if (enableEncryption) {
      final result = await showDialog<EncryptDraftChatResult>(
        context: TwakeApp.routerKey.currentContext ?? context,
        useRootNavigator: false,
        builder: (context) => const EncryptedDraftChatDialog(),
      );

      if (result == null) return;

      switch (result) {
        case EncryptDraftChatResult.cancel:
          return;
        case EncryptDraftChatResult.continueToDraft:
      }
    }

    if (FirstColumnInnerRoutes.instance.goRouteAvailableInFirstColumn()) {
      context.go(
        '/rooms/newprivatechat',
        extra: {
          DraftChatConstant.enableEncryption: enableEncryption,
        },
      );
    } else {
      context.pushInner(
        'innernavigator/newprivatechat',
        arguments: {
          DraftChatConstant.enableEncryption: enableEncryption,
        },
      );
    }
  }
}
