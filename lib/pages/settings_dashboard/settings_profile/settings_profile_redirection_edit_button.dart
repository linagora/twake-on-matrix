import 'package:fluffychat/domain/model/capabilities/capabilities_extension.dart';
import 'package:fluffychat/domain/model/extensions/common_settings/common_settings_extensions.dart';
import 'package:fluffychat/domain/model/extensions/homeserver_summary_extensions.dart';
import 'package:fluffychat/domain/model/user_info/user_info.dart';
import 'package:fluffychat/generated/l10n/app_localizations.dart';
import 'package:fluffychat/widgets/matrix.dart';
import 'package:flutter/material.dart';
import 'package:linagora_design_flutter/colors/linagora_sys_colors.dart';
import 'package:linagora_design_flutter/utils/web_link_generator.dart';
import 'package:matrix/matrix.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsProfileRedirectionEditButton extends StatelessWidget {
  const SettingsProfileRedirectionEditButton({
    super.key,
    required this.capabilities,
    required this.userInfo,
  });

  final Capabilities? capabilities;
  final UserInfo? userInfo;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final matrix = Matrix.of(context);
    final userId = matrix.client.userID;
    final commonSettingsInformation = matrix
        .loginHomeserverSummary
        ?.appTwakeInformation
        ?.commonSettingsInformation;
    final redirectUrl = userId == null
        ? null
        : commonSettingsInformation?.completedApplicationUrl(userId);

    final workplaceFqdn = userInfo?.workplaceFqdn;
    final redirectFqdn = workplaceFqdn == null
        ? null
        : WebLinkGenerator.safeGenerateWebLink(
            workplaceFqdn: workplaceFqdn,
            slug: 'settings',
          );
    final fqdnValid = redirectFqdn != null && redirectFqdn.isNotEmpty;

    if (capabilities?.canEditAvatar == true ||
        capabilities?.canEditDisplayName == true ||
        commonSettingsInformation?.enabled == false ||
        (redirectUrl == null && !fqdnValid)) {
      return const SizedBox();
    }

    return Padding(
      padding: const EdgeInsetsDirectional.only(end: 16),
      child: TextButton(
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          overlayColor: LinagoraSysColors.material().shadow.withValues(
            alpha: 0.2,
          ),
          textStyle: textTheme.labelLarge?.copyWith(
            fontSize: 14,
            height: 20 / 14,
            color: LinagoraSysColors.material().primary,
          ),
        ),
        onPressed: () async {
          try {
            final url = fqdnValid ? redirectFqdn : redirectUrl;
            if (url != null) {
              final success = await launchUrl(
                Uri.parse(url),
                webOnlyWindowName: '_blank',
              );
              if (!success && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(L10n.of(context)!.couldNotLaunchUrl)),
                );
              }
            }
          } catch (e, s) {
            Logs().e('SettingsProfileRedirectionEditButton::onPressed()', e, s);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(L10n.of(context)!.oopsSomethingWentWrong),
                ),
              );
            }
          }
        },
        child: Text(L10n.of(context)!.edit),
      ),
    );
  }
}
