import 'package:fluffychat/pages/chat_details/chat_details_view_style.dart';
import 'package:fluffychat/utils/string_extension.dart';
import 'package:fluffychat/widgets/avatar/avatar_style.dart';
import 'package:fluffychat/widgets/mxc_image.dart';
import 'package:flutter/material.dart';
import 'package:linagora_design_flutter/avatar/round_avatar_style.dart';
import 'package:linagora_design_flutter/extensions/string_extension.dart';

class ChatDetailsGroupSecondaryAvatar extends StatelessWidget {
  final AnimationController animationController;
  final Uri? mxContent;
  final String? name;
  final double fontSize;
  final List<BoxShadow>? boxShadows;
  final Color? textColor;
  final bool keepAlive;

  const ChatDetailsGroupSecondaryAvatar({
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
          cacheWidth:
              (size * MediaQuery.devicePixelRatioOf(context) * 2).round(),
          cacheKey: mxContent.toString(),
          animated: true,
          isThumbnail: false,
          placeholder: (context) => _fallbackAvatar(size),
          keepAlive: keepAlive,
        ),
      ),
    );
  }

  Widget _fallbackAvatar(double size) {
    final text = name?.getShortcutNameForAvatar() ?? '@';
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(
          Tween<double>(
            begin: size / 2,
            end: 0,
          ).transform(animationController.value),
        ),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: text.avatarColors,
          stops: RoundAvatarStyle.defaultGradientStops,
        ),
      ),
      width: size,
      height: size,
      child: Center(
        child: Text(
          text,
          style: TextStyle(
            fontSize: ChatDetailViewStyle.avatarFontSize,
            color: AvatarStyle.defaultTextColor(true),
            fontFamily: AvatarStyle.fontFamily,
            fontWeight: AvatarStyle.fontWeight,
          ),
        ),
      ),
    );
  }
}
