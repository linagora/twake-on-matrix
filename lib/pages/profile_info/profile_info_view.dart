import 'package:fluffychat/utils/clipboard.dart';
import 'package:fluffychat/utils/string_extension.dart';
import 'package:fluffychat/utils/twake_snackbar.dart';
import 'package:fluffychat/widgets/avatar/avatar_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:linagora_design_flutter/avatar/round_avatar_style.dart';
import 'package:linagora_design_flutter/extensions/string_extension.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';

import 'package:fluffychat/pages/profile_info/profile_info.dart';
import 'package:fluffychat/pages/profile_info/profile_info_style.dart';
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
        title: Row(
          children: [
            Padding(
              padding: ProfileInfoStyle.backIconPadding,
              child: IconButton(
                onPressed: controller.widget.onBack,
                icon: controller.widget.isInStack
                    ? const Icon(Icons.arrow_back)
                    : const Icon(Icons.close),
              ),
            ),
            Text(
              L10n.of(context)!.contactInfo,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints:
                const BoxConstraints(maxWidth: ProfileInfoStyle.maxWidth),
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
                      email: contact.email,
                      phoneNumber: null,
                    ),
                  );
                }
                if (contact != null) {
                  return _Information(
                    displayName: contact.displayName,
                    matrixId: contact.matrixId,
                    email: contact.email,
                    phoneNumber: null,
                  );
                }
                return _Information(
                  avatarUri: user?.avatarUrl,
                  displayName: user?.calcDisplayname(),
                  matrixId: user?.id,
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
    this.email,
    this.phoneNumber,
  }) : super(key: key);

  final Uri? avatarUri;
  final String? displayName;
  final String? matrixId;
  final String? email;
  final String? phoneNumber;

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
                      fontSize: ProfileInfoStyle.avatarFontSize,
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
          padding: ProfileInfoStyle.mainPadding,
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
              Text(
                matrixId ?? '',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: LinagoraRefColors.material().tertiary[30],
                    ),
                maxLines: 2,
              ),
              if (email != null || phoneNumber != null)
                Container(
                  padding: ProfileInfoStyle.emailPadding,
                  margin: ProfileInfoStyle.emailMargin,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: LinagoraRefColors.material().neutral[90] ??
                          Colors.black,
                    ),
                    borderRadius: ProfileInfoStyle.emailBorderRadius,
                  ),
                  child: Wrap(
                    runSpacing: ProfileInfoStyle.textSpacing,
                    children: [
                      if (email != null)
                        _CopiableRow(
                          icon: Icons.alternate_email,
                          text: email!,
                        ),
                      if (phoneNumber != null)
                        _CopiableRow(
                          icon: Icons.call,
                          text: phoneNumber!,
                        ),
                    ],
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
          color: LinagoraSysColors.material().onSurface,
        ),
        Expanded(
          child: Padding(
            padding: ProfileInfoStyle.textPadding,
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
