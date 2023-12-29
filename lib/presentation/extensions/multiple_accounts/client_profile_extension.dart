import 'package:fluffychat/presentation/multiple_account/client_profile_presentation.dart';
import 'package:fluffychat/presentation/multiple_account/twake_chat_presentation_account.dart';
import 'package:fluffychat/widgets/avatar/avatar.dart';
import 'package:linagora_design_flutter/multiple_account/models/twake_presentation_account.dart';
import 'package:matrix/matrix.dart';

extension ClientProfileExtension on ClientProfilePresentation {
  TwakeChatPresentationAccount toTwakeChatPresentationAccount(
    Client currentActiveClient,
  ) {
    return TwakeChatPresentationAccount(
      clientAccount: client,
      accountId: profile.userId,
      accountName: profile.displayName ?? '',
      avatar: Avatar(
        mxContent: profile.avatarUrl,
        name: profile.displayName ?? '',
      ),
      accountActiveStatus: profile.userId == currentActiveClient.userID
          ? AccountActiveStatus.active
          : AccountActiveStatus.inactive,
    );
  }
}
