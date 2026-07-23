import 'package:fluffychat/pages/key_verification/key_verification_emoji_view.dart';
import 'package:fluffychat/pages/key_verification/key_verification_error_view.dart';
import 'package:fluffychat/pages/key_verification/key_verification_styles.dart';
import 'package:fluffychat/pages/key_verification/key_verification_success_view.dart';
import 'package:fluffychat/pages/key_verification/key_verification_waiting_view.dart';
import 'package:fluffychat/utils/dialog/twake_dialog.dart';
import 'package:fluffychat/widgets/avatar/avatar_style.dart';
import 'package:fluffychat/widgets/twake_components/twake_text_button.dart';
import 'package:flutter/material.dart';

import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:fluffychat/generated/l10n/app_localizations.dart';
import 'package:linagora_design_flutter/colors/linagora_sys_colors.dart';

import 'package:matrix/encryption.dart';
import 'package:matrix/matrix.dart';

import 'package:fluffychat/utils/adaptive_bottom_sheet.dart';
import 'package:fluffychat/widgets/avatar/avatar.dart';

class KeyVerificationDialog extends StatefulWidget {
  Future<void> show(BuildContext context) => showAdaptiveBottomSheet(
    context: context,
    builder: (context) => this,
    isDismissible: false,
  );

  final KeyVerification request;

  const KeyVerificationDialog({super.key, required this.request});

  @override
  KeyVerificationPageState createState() => KeyVerificationPageState();
}

class KeyVerificationPageState extends State<KeyVerificationDialog> {
  void Function()? originalOnUpdate;

  @override
  void initState() {
    originalOnUpdate = widget.request.onUpdate;
    widget.request.onUpdate = () {
      originalOnUpdate?.call();
      setState(() {});
    };
    widget.request.client.getProfileFromUserId(widget.request.userId).then((p) {
      profile = p;
      setState(() {});
    });
    super.initState();
  }

  @override
  void dispose() {
    widget.request.onUpdate =
        originalOnUpdate; // don't want to get updates anymore
    if (![
      KeyVerificationState.error,
      KeyVerificationState.done,
    ].contains(widget.request.state)) {
      widget.request.cancel('m.user');
    }
    super.dispose();
  }

  Profile? profile;

  Future<void> checkInput(String input) async {
    if (input.isEmpty) return;

    final valid = await TwakeDialog.showFutureLoadingDialogFullScreen(
      future: () async {
        // make sure the loading spinner shows before we test the keys
        await Future.delayed(const Duration(milliseconds: 100));
        var valid = false;
        try {
          await widget.request.openSSSS(keyOrPassphrase: input);
          valid = true;
        } catch (_) {
          valid = false;
        }
        return valid;
      },
    );
    if (valid.error != null) {
      await showOkAlertDialog(
        useRootNavigator: false,
        context: context,
        message: L10n.of(context)!.incorrectPassphraseOrKey,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    User? user;
    final directChatId = widget.request.client.getDirectChatFromUserId(
      widget.request.userId,
    );
    if (directChatId != null) {
      user = widget.request.client
          .getRoomById(directChatId)!
          .unsafeGetUserFromMemoryOrFallback(widget.request.userId);
    }
    final displayName =
        user?.calcDisplayname() ?? widget.request.userId.localpart!;
    Widget title = Text(L10n.of(context)!.verifyTitle);
    Widget body;
    final buttons = <Widget>[];
    switch (widget.request.state) {
      case KeyVerificationState.showQRSuccess:
      case KeyVerificationState.confirmQRScan:
        throw 'Not implemented';
      case KeyVerificationState.askSSSS:
        // prompt the user for their ssss passphrase / key
        final textEditingController = TextEditingController();
        String input;
        body = Container(
          margin: const EdgeInsets.only(left: 8.0, right: 8.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                L10n.of(context)!.askSSSSSign,
                style: const TextStyle(fontSize: 20),
              ),
              Container(height: 10),
              TextField(
                controller: textEditingController,
                autofocus: false,
                autocorrect: false,
                onSubmitted: (s) {
                  input = s;
                  checkInput(input);
                },
                minLines: 1,
                maxLines: 1,
                obscureText: true,
                decoration: InputDecoration(
                  hintText: L10n.of(context)!.passphraseOrKey,
                  prefixStyle: TextStyle(color: Theme.of(context).primaryColor),
                  suffixStyle: TextStyle(color: Theme.of(context).primaryColor),
                  border: const OutlineInputBorder(),
                ),
              ),
            ],
          ),
        );
        buttons.add(
          TwakeTextButton(
            onTap: () => checkInput(textEditingController.text),
            message: L10n.of(context)!.submit,
            borderHover: KeyVerificationStyles.borderHoverButtonWaningBanner,
            styleMessage: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
            margin: KeyVerificationStyles.marginButtonWarningBanner,
            buttonDecoration: BoxDecoration(
              color: LinagoraSysColors.material().onPrimary,
              borderRadius: const BorderRadius.all(Radius.circular(100)),
            ),
          ),
        );
        buttons.add(
          TwakeTextButton(
            onTap: () => widget.request.openSSSS(skip: true),
            message: L10n.of(context)!.skip,
            borderHover: KeyVerificationStyles.borderHoverButtonWaningBanner,
            styleMessage: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
            margin: KeyVerificationStyles.marginButtonWarningBanner,
            buttonDecoration: BoxDecoration(
              color: LinagoraSysColors.material().onPrimary,
              borderRadius: const BorderRadius.all(Radius.circular(100)),
            ),
          ),
        );
        break;
      case KeyVerificationState.askAccept:
        title = Text(L10n.of(context)!.newVerificationRequest);
        body = Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            Avatar(
              mxContent: user?.avatarUrl,
              name: displayName,
              size: AvatarStyle.defaultSize * 2,
            ),
            const SizedBox(height: 16),
            Text(L10n.of(context)!.askVerificationRequest(displayName)),
          ],
        );
        buttons.add(
          TwakeTextButton(
            onTap: () => widget.request.rejectVerification().then(
              (_) => Navigator.maybePop(context),
            ),
            message: L10n.of(context)!.reject,
            borderHover: KeyVerificationStyles.borderHoverButtonWaningBanner,
            styleMessage: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
            margin: KeyVerificationStyles.marginButtonWarningBanner,
            buttonDecoration: BoxDecoration(
              color: LinagoraSysColors.material().onPrimary,
              borderRadius: const BorderRadius.all(Radius.circular(100)),
            ),
          ),
        );
        buttons.add(
          TwakeTextButton(
            onTap: () => widget.request.acceptVerification(),
            message: L10n.of(context)!.accept,
            borderHover: KeyVerificationStyles.borderHoverButtonWaningBanner,
            styleMessage: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: LinagoraSysColors.material().onPrimary,
            ),
            margin: KeyVerificationStyles.marginButtonWarningBanner,
            buttonDecoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              borderRadius: BorderRadius.circular(100),
            ),
          ),
        );
        break;
      case KeyVerificationState.askChoice:
      case KeyVerificationState.waitingAccept:
        title = const SizedBox.shrink();
        body = const KeyVerificationWaitingView();
        break;
      case KeyVerificationState.askSas:
        if (widget.request.sasTypes.contains('emoji')) {
          title = const SizedBox.shrink();
          body = KeyVerificationEmojiView(
            emojis: widget.request.sasEmojis,
            onDontMatch: () => widget.request.rejectSas(),
            onMatch: () => widget.request.acceptSas(),
          );
        } else {
          title = Text(L10n.of(context)!.compareNumbersMatch);
          final numbers = widget.request.sasNumbers;
          final numbstr = '${numbers[0]}-${numbers[1]}-${numbers[2]}';
          body = Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                numbstr,
                style: const TextStyle(fontSize: 40),
                textAlign: TextAlign.center,
              ),
            ],
          );
          buttons.add(
            TwakeTextButton(
              onTap: () => widget.request.rejectSas(),
              message: L10n.of(context)!.theyDontMatch,
              borderHover: KeyVerificationStyles.borderHoverButtonWaningBanner,
              styleMessage: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: Theme.of(context).colorScheme.primary,
              ),
              margin: KeyVerificationStyles.marginButtonWarningBanner,
              buttonDecoration: BoxDecoration(
                color: LinagoraSysColors.material().onPrimary,
                borderRadius: const BorderRadius.all(Radius.circular(100)),
              ),
              constraints: BoxConstraints(
                maxWidth: KeyVerificationStyles.maxWidthMatchButton(context),
              ),
            ),
          );
          buttons.add(
            TwakeTextButton(
              onTap: () => widget.request.acceptSas(),
              message: L10n.of(context)!.theyMatch,
              borderHover: KeyVerificationStyles.borderHoverButtonWaningBanner,
              styleMessage: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: LinagoraSysColors.material().onPrimary,
              ),
              margin: KeyVerificationStyles.marginButtonWarningBanner,
              buttonDecoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(100),
              ),
              constraints: BoxConstraints(
                maxWidth: KeyVerificationStyles.maxWidthMatchButton(context),
              ),
            ),
          );
        }
        break;
      case KeyVerificationState.waitingSas:
        final acceptText = widget.request.sasTypes.contains('emoji')
            ? L10n.of(context)!.waitingPartnerEmoji
            : L10n.of(context)!.waitingPartnerNumbers;
        body = Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const CircularProgressIndicator.adaptive(strokeWidth: 2),
            const SizedBox(height: 10),
            Text(acceptText, textAlign: TextAlign.center),
          ],
        );
        break;
      case KeyVerificationState.done:
        title = const SizedBox.shrink();
        body = KeyVerificationSuccessView(
          onStartChatting: () => Navigator.maybePop(context),
        );
        break;
      case KeyVerificationState.error:
        title = const SizedBox.shrink();
        body = KeyVerificationErrorView(
          canceledCode: widget.request.canceledCode,
          canceledReason: widget.request.canceledReason,
          onClose: () => Navigator.maybePop(context),
        );
        break;
    }
    return Scaffold(
      appBar: AppBar(leading: const CloseButton(), title: title),
      body: ListView(padding: const EdgeInsets.all(12.0), children: [body]),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: buttons,
          ),
        ),
      ),
    );
  }
}
