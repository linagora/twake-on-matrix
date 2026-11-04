import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:linagora_design_flutter/colors/linagora_ref_colors.dart';
import 'package:twake_chat/generated/assets.gen.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:twake_chat/widgets/avatar/avatar.dart';
import 'package:twake_chat/widgets/avatar/avatar_style.dart';

enum AvatarKindBadge { people, public, broadcast }

/// Figma "Avatar icon md (56)": the badge sits in a notch cut out of the avatar.
class AvatarWithKindBadge extends StatelessWidget {
  const AvatarWithKindBadge({
    super.key,
    required this.badge,
    this.mxContent,
    this.name,
    this.size = AvatarStyle.defaultSize,
    this.onTap,
    this.keepAlive = false,
  });

  static const _designSize = 56.0;
  static const _badgeOffset = 38.0;
  static const _badgeSize = 20.0;
  static const _notchRadius = 12.0;
  static const _notchCenter = _badgeOffset + _badgeSize / 2;

  final AvatarKindBadge badge;
  final Uri? mxContent;
  final String? name;
  final double size;
  final VoidCallback? onTap;
  final bool keepAlive;

  @override
  Widget build(BuildContext context) {
    final scale = size / _designSize;
    return SizedBox.square(
      dimension: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ClipPath(
            clipper: _NotchClipper(
              center: Offset(_notchCenter * scale, _notchCenter * scale),
              radius: _notchRadius * scale,
            ),
            child: Avatar(
              mxContent: mxContent,
              name: name,
              size: size,
              onTap: onTap,
              keepAlive: keepAlive,
            ),
          ),
          Positioned(
            left: _badgeOffset * scale,
            top: _badgeOffset * scale,
            child: SvgPicture.asset(
              _assetPath,
              semanticsLabel: _label(L10n.of(context)!),
              width: _badgeSize * scale,
              height: _badgeSize * scale,
              colorFilter: ColorFilter.mode(
                LinagoraRefColors.material().tertiary[30]!,
                BlendMode.srcIn,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _label(L10n l10n) => switch (badge) {
    AvatarKindBadge.people => l10n.roomKindPeople,
    AvatarKindBadge.public => l10n.roomKindPublic,
    AvatarKindBadge.broadcast => l10n.roomKindBroadcast,
  };

  String get _assetPath => switch (badge) {
    AvatarKindBadge.people => Assets.images.icAvatarBadgePeople.path,
    AvatarKindBadge.public => Assets.images.icAvatarBadgePublic.path,
    AvatarKindBadge.broadcast => Assets.images.icAvatarBadgeBroadcast.path,
  };
}

class _NotchClipper extends CustomClipper<Path> {
  const _NotchClipper({required this.center, required this.radius});

  final Offset center;
  final double radius;

  @override
  Path getClip(Size size) => Path.combine(
    PathOperation.difference,
    Path()..addOval(Offset.zero & size),
    Path()..addOval(Rect.fromCircle(center: center, radius: radius)),
  );

  @override
  bool shouldReclip(_NotchClipper oldClipper) =>
      oldClipper.center != center || oldClipper.radius != radius;
}
