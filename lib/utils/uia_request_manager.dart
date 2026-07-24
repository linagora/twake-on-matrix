import 'dart:async';

import 'package:animations/animations.dart';
import 'package:fluffychat/utils/dialog/twake_dialog.dart';
import 'package:fluffychat/utils/url_launcher.dart';
import 'package:fluffychat/widgets/matrix.dart';
import 'package:fluffychat/widgets/twake_app.dart';
import 'package:flutter/material.dart';
import 'package:fluffychat/generated/l10n/app_localizations.dart';
import 'package:linagora_design_flutter/dialog/confirmation_dialog_builder.dart';
import 'package:matrix/matrix.dart';

extension UiaRequestManager on MatrixState {
  /// Same [ConfirmationDialogBuilder] used by [showConfirmAlertDialog], with
  /// a password [TextField] as its `additionalWidgetContent` — replaces
  /// `adaptive_dialog`'s `showTextInputDialog` with the project's own
  /// dialog design while keeping the exact same input/cancel contract.
  Future<String?> _showPasswordInputDialog(BuildContext context) async {
    final l10n = L10n.of(context)!;
    final controller = TextEditingController();
    return showModal<String?>(
      context: context,
      configuration: const FadeScaleTransitionConfiguration(),
      builder: (context) => ConfirmationDialogBuilder(
        title: l10n.pleaseEnterYourPassword,
        confirmText: l10n.ok,
        cancelText: l10n.cancel,
        additionalWidgetContent: TextField(
          controller: controller,
          autofocus: true,
          obscureText: true,
          minLines: 1,
          maxLines: 1,
          decoration: const InputDecoration(hintText: '******'),
        ),
        onConfirmButtonAction: () => Navigator.of(context).pop(controller.text),
        onCancelButtonAction: () => Navigator.of(context).pop(null),
      ),
    );
  }

  Future uiaRequestHandler(UiaRequest uiaRequest) async {
    final l10n = L10n.of(context)!;
    try {
      if (uiaRequest.state != UiaRequestState.waitForUser ||
          uiaRequest.nextStages.isEmpty) {
        Logs().d('Uia Request Stage: ${uiaRequest.state}');
        return;
      }
      final stage = uiaRequest.nextStages.first;
      Logs().d('Uia Request Stage: $stage');
      switch (stage) {
        case AuthenticationTypes.password:
          final input =
              cachedPassword ??
              await _showPasswordInputDialog(
                TwakeApp.routerKey.currentContext!,
              );
          if (input == null || input.isEmpty) {
            return uiaRequest.cancel();
          }
          return uiaRequest.completeStage(
            AuthenticationPassword(
              session: uiaRequest.session,
              password: input,
              identifier: AuthenticationUserIdentifier(user: client.userID!),
            ),
          );
        case AuthenticationTypes.emailIdentity:
          if (currentThreepidCreds == null) {
            return uiaRequest.cancel(
              UiaException(L10n.of(context)!.serverRequiresEmail),
            );
          }
          final auth = AuthenticationThreePidCreds(
            session: uiaRequest.session,
            type: AuthenticationTypes.emailIdentity,
            threepidCreds: ThreepidCreds(
              sid: currentThreepidCreds!.sid,
              clientSecret: currentClientSecret,
            ),
          );
          if (ConfirmResult.ok ==
              await showConfirmAlertDialog(
                useRootNavigator: false,
                context: TwakeApp.routerKey.currentContext!,
                title: l10n.weSentYouAnEmail,
                message: l10n.pleaseClickOnLink,
                okLabel: l10n.iHaveClickedOnLink,
                cancelLabel: l10n.cancel,
              )) {
            return uiaRequest.completeStage(auth);
          }
          return uiaRequest.cancel();
        case AuthenticationTypes.dummy:
          return uiaRequest.completeStage(
            AuthenticationData(
              type: AuthenticationTypes.dummy,
              session: uiaRequest.session,
            ),
          );
        default:
          final url = Uri.parse(
            '${client.homeserver}/_matrix/client/r0/auth/$stage/fallback/web?session=${uiaRequest.session}',
          );
          UrlLauncher(context, url: url.toString()).openUrlInAppBrowser();
          if (ConfirmResult.ok ==
              await showConfirmAlertDialog(
                useRootNavigator: false,
                message: l10n.pleaseFollowInstructionsOnWeb,
                context: TwakeApp.routerKey.currentContext!,
                okLabel: l10n.next,
                cancelLabel: l10n.cancel,
              )) {
            return uiaRequest.completeStage(
              AuthenticationData(session: uiaRequest.session),
            );
          } else {
            return uiaRequest.cancel();
          }
      }
    } catch (e, s) {
      Logs().e('Error while background UIA', e, s);
      return uiaRequest.cancel(e is Exception ? e : Exception(e));
    }
  }
}

class UiaException implements Exception {
  final String reason;

  UiaException(this.reason);

  @override
  String toString() => reason;
}
