import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:fluffychat/resource/image_paths.dart';
import 'package:linagora_design_flutter/colors/linagora_ref_colors.dart';

class GroupChatEmptyView extends StatelessWidget {

  const GroupChatEmptyView({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      constraints: const BoxConstraints(
        maxWidth: 256,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 2,),
          SvgPicture.asset(ImagePaths.icEmptyGroupChat),
          const SizedBox(height: 26.0,),
          Text(
            L10n.of(context)!.youCreatedGroupChat,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 17,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Text(
                L10n.of(context)!.groupChatsCanHave,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.w400,
                  fontSize: 15,
                  color: LinagoraRefColors.material().neutral[40],
                ),
              ),
              const Expanded(child: SizedBox())
            ],
          ),
          const SizedBox(height: 8),
          _ruleChannel(L10n.of(context)!.upTo100000Members),
          const SizedBox(height: 8),
          _ruleChannel(L10n.of(context)!.persistentChatHistory),
          const SizedBox(height: 8),
          _ruleChannel(L10n.of(context)!.multiInteractionThreadedDiscussion),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _ruleChannel(String rule) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SvgPicture.asset(
          ImagePaths.icDone,
          width: 20,
          height: 20,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            rule,
            style: TextStyle(
              fontWeight: FontWeight.w400,
              fontSize: 15,
              color: LinagoraRefColors.material().neutral[40],
            ),
          ),
        ),
      ],
    );
  }
}