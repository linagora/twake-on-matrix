import 'package:fluffychat/config/app_config.dart';
import 'package:fluffychat/pages/forward/forward_item_style.dart';
import 'package:fluffychat/widgets/avatar/avatar.dart';
import 'package:flutter/material.dart';
import 'package:linagora_design_flutter/colors/linagora_sys_colors.dart';

class ForwardItem extends StatelessWidget {
  final String id;
  final String displayName;
  final Uri? uriAvatar;
  final bool selected;
  final void Function()? onTap;

  const ForwardItem({
    required this.id,
    required this.displayName,
    this.selected = false,
    this.uriAvatar,
    this.onTap,
    Key? key,
    }
  ) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      borderRadius: BorderRadius.circular(AppConfig.borderRadius),
      clipBehavior: Clip.hardEdge,
      color: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Theme(
          data: ThemeData(
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
          ),
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            title: Row(
              children: [
                SizedBox(
                  width: ForwardItemStyle.avatarSize,
                  child: Stack(
                    children: [
                      Avatar(
                        mxContent: uriAvatar,
                        name: displayName,
                      ),
                      if (selected)
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            width: ForwardItemStyle.selectedContainerSize,
                            height: ForwardItemStyle.selectedContainerSize,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle
                            ),
                            child: Icon(
                              Icons.check_circle,
                              size: ForwardItemStyle.selectedIconSize,
                              color: LinagoraSysColors.material().primary))),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    displayName,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    softWrap: false,
                    style: Theme.of(context).textTheme.titleMedium?.merge(
                      TextStyle(
                        overflow: TextOverflow.ellipsis,
                        letterSpacing: 0.15,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
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
