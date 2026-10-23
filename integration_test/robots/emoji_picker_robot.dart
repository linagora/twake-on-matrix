import 'package:flutter/material.dart';
import 'package:flutter_emoji_mart/flutter_emoji_mart.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

import '../base/core_robot.dart';

/// Full emoji picker (`flutter_emoji_mart`) opened from the reaction row.
///
/// The same widget is shown on mobile (inside the long-press dialog) and on web
/// (inside the hover reaction popup), so this robot is platform-agnostic.
class EmojiPickerRobot extends CoreRobot {
  EmojiPickerRobot(super.$);

  PatrolFinder get picker => $(EmojiPicker);

  Future<void> waitUntilVisible() async {
    await $.waitUntilVisible(picker, timeout: const Duration(seconds: 15));
  }

  Future<void> search(String keyword) async {
    final field = picker.$(TextField);
    await $.waitUntilVisible(field);
    await $.tester.enterText(field.finder, keyword);
    await $.pump(const Duration(milliseconds: 500));
  }

  Future<void> tapEmoji(String emoji) async {
    final item = picker.$(EmojiItem).containing(find.text(emoji)).first;
    await $.waitUntilVisible(item, timeout: const Duration(seconds: 10));
    await $.tester.tap(item.finder);
    await $.pump(const Duration(milliseconds: 300));
    await $.pumpAndTrySettle();
  }

  /// The "Recent" section is keyed by its category id in emoji_mart and lists
  /// the most recent reaction first.
  Future<void> expectFirstInRecent(String emoji) async {
    final firstRecent = $(
      find.descendant(
        of: find.byKey(
          const ValueKey(EmojiPickerConfiguration.recentCategoryId),
        ),
        matching: find.byType(EmojiItem),
      ),
    ).first;
    await $.waitUntilVisible(firstRecent, timeout: const Duration(seconds: 10));
    final emojiInFirst = $(
      find.descendant(of: firstRecent.finder, matching: find.text(emoji)),
    );
    await $.waitUntilVisible(
      emojiInFirst,
      timeout: const Duration(seconds: 10),
    );
  }

  Future<void> close() async {
    // Both the mobile dialog and the web popup pop when their barrier is tapped.
    await $.tester.tapAt(const Offset(10, 10));
    await $.pump(const Duration(milliseconds: 300));
    await $.pumpAndTrySettle();
  }
}
