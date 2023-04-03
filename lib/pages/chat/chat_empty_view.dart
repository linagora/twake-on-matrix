import 'package:fluffychat/resource/colors.dart';
import 'package:fluffychat/resource/image_paths.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ChatEmptyView extends StatelessWidget {
  const ChatEmptyView({
    Key? key,
    required this.isDirectChat,
  }) : super(key: key);

  final bool isDirectChat;

  @override
  Widget build(BuildContext context) {
    if (isDirectChat) {
      return Container(
        padding: const EdgeInsets.all(16),
        constraints: const BoxConstraints(
          maxWidth: 236,
        ),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.04),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              L10n.of(context)!.noMessageHereYet,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 17,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              L10n.of(context)!.sendMessageGuide,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.w400,
                fontSize: 15,
                color: Color(0xFF818C99),
              ),
            ),
            const SizedBox(height: 8),
            SvgPicture.asset(
              ImagePaths.bannerEmptyChat,
              width: 128,
              height: 128,
            ),
          ],
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.all(16),
        constraints: const BoxConstraints(
          maxWidth: 256,
        ),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.04),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              L10n.of(context)!.youCreatedAChanel,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 17,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              L10n.of(context)!.chanelCanHave,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.w400,
                fontSize: 15,
                color: Color(0xFF818C99),
              ),
            ),
            const SizedBox(height: 8),
            _ruleChanel(L10n.of(context)!.upTo100000Members),
            const SizedBox(height: 8),
            _ruleChanel(L10n.of(context)!.persistentChatHistory),
            const SizedBox(height: 8),
            _ruleChanel(L10n.of(context)!.multiInteractionThreadedDiscussion),
            const SizedBox(height: 24),
            _buttonAddMember(context),
          ],
        ),
      );
    }
  }

  Widget _ruleChanel(String rule) {
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
            style: const TextStyle(
              fontWeight: FontWeight.w400,
              fontSize: 15,
              color: Color(0xFF818C99),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buttonAddMember(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SvgPicture.asset(
          ImagePaths.icAdd,
          width: 20,
          height: 20,
        ),
        const SizedBox(width: 8),
        Text(
          L10n.of(context)!.addMember,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontWeight: FontWeight.w400,
            fontSize: 15,
            color: AppColor.primary,
          ),
        ),
      ],
    );
  }
}
