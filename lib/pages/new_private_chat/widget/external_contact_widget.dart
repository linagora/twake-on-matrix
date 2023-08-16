import 'package:fluffychat/presentation/model/presentation_contact.dart';
import 'package:flutter/material.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';

import 'package:fluffychat/config/app_config.dart';
import 'package:fluffychat/pages/search/recent_item_widget_style.dart';
import 'package:fluffychat/widgets/avatar/avatar.dart';

class ExternalContactWidget extends StatelessWidget {
  final PresentationContact contact;
  final void Function() onTap;

  const ExternalContactWidget({
    required this.contact,
    required this.onTap,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      borderRadius: BorderRadius.circular(AppConfig.borderRadius),
      clipBehavior: Clip.hardEdge,
      color: Colors.transparent,
      child: Padding(
        padding: RecentItemStyle.paddingRecentItem,
        child: Theme(
          data: ThemeData(
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
          ),
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            title: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: RecentItemStyle.avatarSize,
                  child: Avatar(
                    name: contact.displayName,
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        contact.matrixId ?? "",
                        overflow: TextOverflow.ellipsis,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                      ),
                      Text(
                        contact.email ?? "",
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: LinagoraRefColors.material().tertiary[30],
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            onTap: onTap,
          ),
        ),
      ),
    );
  }
}
