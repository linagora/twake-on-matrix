import 'package:fluffychat/pages/chat_details/chat_details_view_style.dart';
import 'package:fluffychat/widgets/avatar/avatar_gradient_placeholder.dart';
import 'package:fluffychat/widgets/avatar/avatar_style.dart';
import 'package:fluffychat/widgets/mxc_image.dart';
import 'package:flutter/material.dart';

class SecondaryAvatar extends StatelessWidget {
  final AnimationController animationController;
  final Uri? mxContent;
  final String? name;
  final double fontSize;
  final List<BoxShadow>? boxShadows;
  final Color? textColor;
  final bool keepAlive;

  const SecondaryAvatar({
    required this.animationController,
    this.mxContent,
    this.name,
    this.fontSize = AvatarStyle.defaultFontSize,
    this.boxShadows,
    this.textColor,
    this.keepAlive = false,
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
    );
  }
}
