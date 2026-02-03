import 'package:fluffychat/utils/string_extension.dart';
import 'package:fluffychat/widgets/avatar/avatar_style.dart';
import 'package:fluffychat/widgets/mxc_image.dart';
import 'package:flutter/material.dart';
import 'package:linagora_design_flutter/avatar/round_avatar.dart';

class Avatar extends StatelessWidget {
  final Uri? mxContent;
  final String? name;
  final double size;
  final double? sizeWidth;
  final void Function()? onTap;
  final double fontSize;
  final List<BoxShadow>? boxShadows;
  final Color? textColor;
  final bool keepAlive;
  final bool isCircle;

  const Avatar({
    this.mxContent,
    this.name,
    this.size = AvatarStyle.defaultSize,
    this.sizeWidth,
    this.onTap,
    this.fontSize = AvatarStyle.defaultFontSize,
    this.boxShadows,
    this.textColor,
    this.keepAlive = false,
    this.isCircle = true,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      type: MaterialType.transparency,
      shadowColor: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: isCircle ? BorderRadius.circular(size / 2) : null,
        child: ClipRRect(
          borderRadius:
              isCircle ? BorderRadius.circular(size / 2) : BorderRadius.zero,
          child: MxcImage(
            key: Key(mxContent.toString()),
            uri: mxContent,
            rounded: isCircle,
            fit: BoxFit.cover,
            width: sizeWidth ?? size,
            height: size,
            cacheWidth: (size * MediaQuery.devicePixelRatioOf(context) * 2)
                .round(),
            cacheKey: mxContent.toString(),
            animated: true,
            isThumbnail: false,
            placeholder: (context) => _fallbackAvatar(),
            keepAlive: keepAlive,
          ),
        ),
      ),
    );
  }

  Widget _fallbackAvatar() {
    final fallbackLetters = name?.getShortcutNameForAvatar() ?? '@';
    return RoundAvatar(
      size: size,
      text: fallbackLetters,
      boxShadows: boxShadows,
      textStyle: TextStyle(
        fontSize: fontSize,
        color: textColor ?? AvatarStyle.defaultTextColor(_havePicture),
        fontFamily: AvatarStyle.fontFamily,
        fontWeight: AvatarStyle.fontWeight,
      ),
    );
  }

  bool get _havePicture {
    return mxContent == null ||
        mxContent.toString().isEmpty ||
        mxContent.toString() == 'null';
  }
}
