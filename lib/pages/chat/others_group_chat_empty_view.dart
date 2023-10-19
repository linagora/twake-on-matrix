import 'package:fluffychat/utils/date_time_extension.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions/event_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:fluffychat/resource/image_paths.dart';
import 'package:linagora_design_flutter/colors/linagora_ref_colors.dart';
import 'package:matrix/matrix.dart';

class OthersGroupChatEmptyView extends StatelessWidget {
  final Event firstEvent;
  const OthersGroupChatEmptyView({super.key, required this.firstEvent});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(
        maxWidth: 224,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _getDateWidget(context, firstEvent),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.secondaryContainer,
              shape: BoxShape.circle,
            ),
            padding: const EdgeInsets.all(10),
            child: SvgPicture.asset(
              ImagePaths.icUsersOutline,
              colorFilter: ColorFilter.mode(
                Theme.of(context).primaryColor,
                BlendMode.srcIn,
              ),
            ),
          ),
          const SizedBox(height: 12),
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              children: [
                TextSpan(
                  text: firstEvent.getUser()?.displayName,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontSize: 14,
                        color: LinagoraRefColors.material().neutral[40],
                      ),
                ),
                const TextSpan(text: ' ', style: TextStyle(fontSize: 14)),
                TextSpan(
                  text: L10n.of(context)!
                      .hasCreatedAGroupChat(firstEvent.room.name),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontSize: 14,
                        color: LinagoraRefColors.material().neutral[60],
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _getDateWidget(BuildContext context, Event firstEvent) {
    final eventDateTime = firstEvent.originServerTs;

    return Text(
      eventDateTime.relativeTime(context),
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w500,
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurface,
          ),
    );
  }
}
