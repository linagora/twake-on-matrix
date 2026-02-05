import 'package:fluffychat/utils/string_extension.dart';
import 'package:fluffychat/widgets/avatar/avatar_style.dart';
import 'package:flutter/material.dart';
import 'package:linagora_design_flutter/avatar/round_avatar_style.dart';
import 'package:linagora_design_flutter/extensions/string_extension.dart';

/// A gradient placeholder that displays initials derived from [name].
///
/// Used as a fallback when no avatar image is available.  The gradient
/// colours are deterministically derived from the initials text so that
/// the same name always produces the same placeholder appearance.
class AvatarGradientPlaceholder extends StatelessWidget {
  const AvatarGradientPlaceholder({
    super.key,
    this.name,
    required this.width,
    required this.height,
    required this.fontSize,
    this.borderRadius = BorderRadius.zero,
  });

  /// The display name used to derive the initials and gradient colours.
  final String? name;

  final double width;
  final double height;
  final double fontSize;

  /// Border radius applied to the placeholder container.
  /// Defaults to [BorderRadius.zero].
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    final text = name?.getShortcutNameForAvatar() ?? '@';
    return Container(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: text.avatarColors,
          stops: RoundAvatarStyle.defaultGradientStops,
        ),
      ),
      width: width,
      height: height,
      child: Center(
        child: Text(
          text,
          style: TextStyle(
            fontSize: fontSize,
            color: AvatarStyle.defaultTextColor(true),
            fontFamily: AvatarStyle.fontFamily,
            fontWeight: AvatarStyle.fontWeight,
          ),
        ),
      ),
    );
  }
}
