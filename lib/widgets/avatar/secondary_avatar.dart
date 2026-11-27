import 'package:twake_chat/pages/chat_details/chat_details_view_style.dart';
import 'package:twake_chat/widgets/avatar/avatar_gradient_placeholder.dart';
import 'package:twake_chat/widgets/avatar/avatar_style.dart';
import 'package:twake_chat/widgets/mxc_image.dart';
import 'package:flutter/material.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';

class SecondaryAvatar extends StatelessWidget {
  final AnimationController animationController;
  final Uri? mxContent;
  final String? name;
  final double fontSize;
  final List<BoxShadow>? boxShadows;
  final Color? textColor;
  final bool keepAlive;
  final LinagoraPresence? presence;

  /// The colour behind the avatar, around the presence dot.
  final Color? presenceRingColor;

  const SecondaryAvatar({
    required this.animationController,
    this.mxContent,
    this.name,
    this.fontSize = AvatarStyle.defaultFontSize,
    this.boxShadows,
    this.textColor,
    this.keepAlive = false,
    this.presence,
    this.presenceRingColor,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final size = Tween<double>(
      begin: ChatDetailViewStyle.avatarSize,
      end: screenWidth,
    ).transform(animationController.value);
    return Container(
      padding: EdgeInsets.only(
        top: Tween<double>(
          begin: 16,
          end: 0,
        ).transform(animationController.value),
      ),
      alignment: Alignment.topCenter,
      // The dot belongs to the round avatar, not to the expanded picture
      child: LinagoraPresenceBadge(
        presence: animationController.value == 0 ? presence : null,
        size: size,
        style: LinagoraPresenceBadgeStyle.material().copyWith(
          ringColor: presenceRingColor,
        ),
        child: ClipRRect(
          borderRadius: Tween<BorderRadius>(
            begin: BorderRadius.circular(size / 2),
            end: BorderRadius.zero,
          ).transform(animationController.value),
          child: MxcImage(
            key: Key(mxContent.toString()),
            uri: mxContent,
            fit: BoxFit.cover,
            width: size,
            height: size,
            cacheWidth: (size * MediaQuery.devicePixelRatioOf(context) * 2)
                .round(),
            cacheKey: mxContent.toString(),
            animated: true,
            isThumbnail: false,
            placeholder: (_) => AvatarGradientPlaceholder(
              name: name,
              width: size,
              height: size,
              fontSize: fontSize,
              borderRadius: BorderRadius.circular(
                Tween<double>(
                  begin: size / 2,
                  end: 0,
                ).transform(animationController.value),
              ),
            ),
            keepAlive: keepAlive,
          ),
        ),
      ),
    );
  }
}
