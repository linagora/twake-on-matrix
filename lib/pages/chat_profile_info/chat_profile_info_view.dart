import 'package:dartz/dartz.dart';
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/domain/app_state/contact/lookup_match_contact_state.dart';
import 'package:fluffychat/utils/clipboard.dart';
import 'package:fluffychat/utils/string_extension.dart';
import 'package:fluffychat/utils/twake_snackbar.dart';
import 'package:fluffychat/widgets/avatar/avatar_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:linagora_design_flutter/avatar/round_avatar_style.dart';
import 'package:linagora_design_flutter/extensions/string_extension.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';

import 'package:fluffychat/pages/chat_profile_info/chat_profile_info.dart';
import 'package:fluffychat/pages/chat_profile_info/chat_profile_info_style.dart';
import 'package:fluffychat/widgets/matrix.dart';
import 'package:fluffychat/widgets/mxc_image.dart';

class ProfileInfoView extends StatelessWidget {
  final ProfileInfoController controller;

  const ProfileInfoView(
    this.controller, {
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final user = controller.user;
    final contact = controller.widget.contact;
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        centerTitle: false,
        leading: Padding(
          padding: ChatProfileInfoStyle.backIconPadding,
          child: IconButton(
            splashColor: Colors.transparent,
            hoverColor: Colors.transparent,
            highlightColor: Colors.transparent,
            onPressed: controller.widget.onBack,
            icon: controller.widget.isInStack
                ? const Icon(Icons.arrow_back)
                : const Icon(Icons.close),
          ),
        ),
        leadingWidth: 40,
        title: Text(
          L10n.of(context)!.contactInfo,
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints:
                const BoxConstraints(maxWidth: ChatProfileInfoStyle.maxWidth),
            child: Builder(
              builder: (context) {
                if (contact?.matrixId != null) {
                  return FutureBuilder(
                    future: Matrix.of(context).client.getProfileFromUserId(
                          contact!.matrixId!,
                          getFromRooms: false,
                        ),
                    builder: (context, snapshot) => _Information(
                      avatarUri: snapshot.data?.avatarUrl,
                      displayName:
                          snapshot.data?.displayName ?? contact.displayName,
                      matrixId: contact.matrixId,
                      lookupContactNotifier: controller.lookupContactNotifier,
                      goToProfileShared: controller.goToProfileShared,
                    ),
                  );
                }
                if (contact != null) {
                  return _Information(
                    displayName: contact.displayName,
                    matrixId: contact.matrixId,
                    lookupContactNotifier: controller.lookupContactNotifier,
                    goToProfileShared: controller.goToProfileShared,
                  );
                }
                return _Information(
                  avatarUri: user?.avatarUrl,
                  displayName: user?.calcDisplayname(),
                  matrixId: user?.id,
                  lookupContactNotifier: controller.lookupContactNotifier,
                  goToProfileShared: controller.goToProfileShared,
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _Information extends StatelessWidget {
  static const double avatarRatio = 1;

  const _Information({
    Key? key,
    this.avatarUri,
    this.displayName,
    this.matrixId,
    required this.lookupContactNotifier,
    this.goToProfileShared,
  }) : super(key: key);

  final Uri? avatarUri;
  final String? displayName;
  final String? matrixId;
  final ValueNotifier<Either<Failure, Success>> lookupContactNotifier;
  final Function()? goToProfileShared;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LayoutBuilder(
          builder: (context, constraints) => Builder(
            builder: (context) {
              final text = displayName?.getShortcutNameForAvatar() ?? '@';
              final placeholder = Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: text.avatarColors,
                    stops: RoundAvatarStyle.defaultGradientStops,
                  ),
                ),
                width: constraints.maxWidth,
                height: constraints.maxWidth * avatarRatio,
                child: Center(
                  child: Text(
                    text,
                    style: TextStyle(
                      fontSize: ChatProfileInfoStyle.avatarFontSize,
                      color: AvatarStyle.defaultTextColor(true),
                      fontFamily: AvatarStyle.fontFamily,
                      fontWeight: AvatarStyle.fontWeight,
                    ),
                  ),
                ),
              );
              if (avatarUri == null) {
                return placeholder;
              }
              return MxcImage(
                uri: avatarUri,
                width: constraints.maxWidth,
                height: constraints.maxWidth * avatarRatio,
                fit: BoxFit.cover,
                placeholder: (_) => placeholder,
                cacheKey: avatarUri.toString(),
                noResize: true,
              );
            },
          ),
        ),
        Padding(
          padding: ChatProfileInfoStyle.mainPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                displayName ?? '',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: LinagoraSysColors.material().onSurface,
                    ),
                maxLines: 2,
              ),
              Row(
                children: [
                  Text(
                    matrixId ?? '',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: LinagoraRefColors.material().tertiary[30],
                        ),
                    maxLines: 2,
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(
                      Icons.content_copy,
                      size: ChatProfileInfoStyle.copyIconSize,
                      color: LinagoraRefColors.material().tertiary[40],
                    ),
                    color: LinagoraRefColors.material().tertiary[40],
                    onPressed: () {
                      Clipboard.instance.copyText(matrixId ?? '');
                      TwakeSnackBar.show(
                        context,
                        L10n.of(context)!.copiedToClipboard,
                      );
                    },
                  ),
                ],
              ),
              ValueListenableBuilder(
                valueListenable: lookupContactNotifier,
                builder: (context, contact, child) {
                  return contact.fold(
                    (failure) => const SizedBox.shrink(),
                    (success) {
                      if (success is LookupMatchContactSuccess) {
                        return Container(
                          padding: ChatProfileInfoStyle.emailPadding,
                          margin: ChatProfileInfoStyle.emailMargin,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: LinagoraRefColors.material().neutral[90] ??
                                  Colors.black,
                            ),
                            borderRadius:
                                ChatProfileInfoStyle.emailBorderRadius,
                          ),
                          child: Wrap(
                            runSpacing: ChatProfileInfoStyle.textSpacing,
                            children: [
                              if (success.contact.email != null)
                                _CopiableRow(
                                  icon: Icons.alternate_email,
                                  text: success.contact.email!,
                                ),
                              if (success.contact.phoneNumber != null)
                                _CopiableRow(
                                  icon: Icons.call,
                                  text: success.contact.phoneNumber!,
                                ),
                            ],
                          ),
                        );
                      }

                      return const SizedBox.shrink();
                    },
                  );
                },
                child: const SizedBox.shrink(),
              ),
              InkWell(
                splashColor: Colors.transparent,
                hoverColor: Colors.transparent,
                highlightColor: Colors.transparent,
                onTap: goToProfileShared,
                child: Padding(
                  padding: ChatProfileInfoStyle.titleSharedMediaAndFilesPadding,
                  child: Row(
                    children: [
                      Text(
                        L10n.of(context)!.sharedMediaAndFiles,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const Spacer(),
                      Icon(
                        Icons.arrow_forward,
                        size: 18,
                        color: LinagoraSysColors.material().onSurface,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CopiableRow extends StatelessWidget {
  const _CopiableRow({
    Key? key,
    required this.icon,
    required this.text,
  }) : super(key: key);

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: ChatProfileInfoStyle.copyIconSize,
          color: LinagoraSysColors.material().onSurface,
        ),
        Expanded(
          child: Padding(
            padding: ChatProfileInfoStyle.textPadding,
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: LinagoraSysColors.material().onSurface,
                  ),
            ),
          ),
        ),
        IconButton(
          icon: Icon(
            Icons.content_copy,
            size: ChatProfileInfoStyle.copyIconSize,
            color: LinagoraRefColors.material().tertiary[40],
          ),
          color: LinagoraRefColors.material().tertiary[40],
          onPressed: () {
            Clipboard.instance.copyText(text);
            TwakeSnackBar.show(context, L10n.of(context)!.copiedToClipboard);
          },
        ),
      ],
    );
  }
}
