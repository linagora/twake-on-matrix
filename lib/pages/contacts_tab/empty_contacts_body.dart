import 'package:fluffychat/resource/image_paths.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:fluffychat/generated/l10n/app_localizations.dart';
import 'package:linagora_design_flutter/colors/linagora_ref_colors.dart';

class EmptyContactBody extends StatelessWidget {
  const EmptyContactBody({super.key, this.onRetrySyncContacts});

  final VoidCallback? onRetrySyncContacts;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 100),
          SvgPicture.asset(ImagePaths.icSkeletons),
          const SizedBox(height: 16.0),
          Text(
            L10n.of(context)!.soonThereHaveContacts,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              // TODO: change to colorSurface when its approved
              // ignore: deprecated_member_use
              color: Theme.of(context).colorScheme.onBackground,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8.0),
          Text(
            L10n.of(context)!.searchSuggestion,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: LinagoraRefColors.material().neutral[40],
            ),
            textAlign: TextAlign.center,
          ),
          if (onRetrySyncContacts != null) ...[
            const SizedBox(height: 16.0),
            FilledButton.icon(
              onPressed: onRetrySyncContacts,
              icon: const Icon(Icons.sync, size: 20.0),
              label: Text(L10n.of(context)!.tapToRetry),
              style: FilledButton.styleFrom(shape: const StadiumBorder()),
            ),
          ],
        ],
      ),
    );
  }
}
