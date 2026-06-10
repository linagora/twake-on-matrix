import 'package:fluffychat/pages/profile_info/profile_info_body/profile_info_body.dart';
import 'package:fluffychat/pages/profile_info/profile_info_body/profile_info_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../chat/chat_profile_info_robot.dart';

/// Web-specific member profile-info robot.
///
/// On web (wide layout) the profile opens inside an `AlertDialog` hosting
/// `ProfileInfoBody`, layered over the group-information pane that still
/// shows the same member name and matrix id — so the mobile robot's
/// unscoped `find.text(...)`/`findsOneWidget` assertions match both and
/// fail. All reads and assertions are scoped to `ProfileInfoBody`. The
/// avatar's fallback initial also renders as the first `Text` of
/// `ProfileInfoHeader`, so the display name is matched on its
/// `maxLines: 2` style instead of taking the first text.
class WebChatProfileInfoRobot extends ChatProfileInfoRobot {
  WebChatProfileInfoRobot(super.$);

  Finder get _scope => find.byType(ProfileInfoBody);

  @override
  Future<String> getDisplayName() async {
    await $(ProfileInfoHeader).waitUntilExists();
    final texts = find
        .descendant(
          of: find.byType(ProfileInfoHeader),
          matching: find.byType(Text),
        )
        .evaluate()
        .map((element) => element.widget as Text);
    // The avatar's fallback initial renders as the first header text
    // (single character); the display name is the first text after it —
    // before any presence label.
    for (final text in texts) {
      final data = text.data ?? '';
      if (data.length > 1) {
        return data;
      }
    }
    return '';
  }

  @override
  Future<void> verifyDisplayName({required String displayName}) async {
    expect(
      find.descendant(of: _scope, matching: find.text(displayName)),
      findsWidgets,
    );
  }

  @override
  Future<void> verifyDisplayMatrixId({required String matrixId}) async {
    expect(
      find.descendant(of: _scope, matching: find.text(matrixId)),
      findsWidgets,
    );
  }

  @override
  Future<void> verifyEmail({required String email}) async {
    final emailFinder = find.descendant(of: _scope, matching: find.text(email));
    if (email.isEmpty) {
      expect(emailFinder, findsNothing);
      return;
    }
    expect(emailFinder, findsWidgets);
  }

  @override
  Future<void> verifyPhoneNumber({required String phoneNumber}) async {
    final phoneFinder = find.descendant(
      of: _scope,
      matching: find.text(phoneNumber),
    );
    if (phoneNumber.isEmpty) {
      expect(phoneFinder, findsNothing);
      return;
    }
    expect(phoneFinder, findsWidgets);
  }
}
