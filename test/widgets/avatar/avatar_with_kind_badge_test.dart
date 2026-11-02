import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/generated/assets.gen.dart';
import 'package:twake_chat/widgets/avatar/avatar.dart';
import 'package:twake_chat/widgets/avatar/avatar_with_kind_badge.dart';

void main() {
  Future<void> pumpBadge(WidgetTester tester, AvatarKindBadge badge) =>
      tester.pumpWidget(
        MaterialApp(
          home: Center(
            child: AvatarWithKindBadge(badge: badge, name: 'Team'),
          ),
        ),
      );

  String badgeAsset(WidgetTester tester) {
    final loader =
        tester.widget<SvgPicture>(find.byType(SvgPicture)).bytesLoader
            as SvgAssetLoader;
    return loader.assetName;
  }

  for (final (badge, asset) in [
    (AvatarKindBadge.group, Assets.images.icAvatarBadgeGroup.path),
    (
      AvatarKindBadge.publicChannel,
      Assets.images.icAvatarBadgeChannelPublic.path,
    ),
    (
      AvatarKindBadge.privateChannel,
      Assets.images.icAvatarBadgeChannelPrivate.path,
    ),
  ]) {
    testWidgets('build_whenBadgeIs${badge.name}_showsItsIcon', (tester) async {
      // Act
      await pumpBadge(tester, badge);

      // Assert
      expect(find.byType(Avatar), findsOneWidget);
      expect(badgeAsset(tester), asset);
    });
  }

  testWidgets('build_always_placesTheBadgeAsInFigma', (tester) async {
    // Act
    await pumpBadge(tester, AvatarKindBadge.group);

    // Assert
    final avatarOrigin = tester.getTopLeft(find.byType(AvatarWithKindBadge));
    final badgeRect = tester.getRect(find.byType(SvgPicture));
    expect(badgeRect.topLeft - avatarOrigin, const Offset(38, 38));
    expect(badgeRect.size, const Size(20, 20));
  });
}
