import 'package:fluffychat/pages/chat/chat_view.dart';
import 'package:fluffychat/pages/new_group/contacts_selection_view.dart';
import 'package:fluffychat/pages/profile_info/profile_info_view.dart';
import 'package:fluffychat/utils/warning_dialog.dart';
import 'package:fluffychat/widgets/twake_components/twake_icon_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';
import 'package:patrol/patrol.dart';
import '../base/core_robot.dart';
import 'twake_list_item_robot.dart';

class GroupInformationRobot extends CoreRobot {
  GroupInformationRobot(super.$);

  PatrolFinder getBackIcon() {
    return $(AppBar).$(TwakeIconButton);
  }

  PatrolFinder getTitle() {
    return $(AppBar).$(Text);
  }

  PatrolFinder getEditTitleIcon() {
    return $(AppBar).$(IconButton);
  }

  PatrolFinder getNotificationToggle() {
    return $(Switch);
  }

  PatrolFinder getMemberTab() {
    return $(Tab).containing(find.text('Members'));
  }

  PatrolFinder getMediaTab() {
    return $(Tab).containing(find.text('Media'));
  }

  PatrolFinder getLinksTab() {
    return $(Tab).containing(find.text('Links'));
  }

  PatrolFinder getFilesTab() {
    return $(Tab).containing(find.text('Files'));
  }

  PatrolFinder getAddMembersBtn() {
    return $(InkWell).containing(find.text('Add members'));
  }

  PatrolFinder getMember(String account) {
    return $(TwakeListItem).containing(find.text(account));
  }

  PatrolFinder getcRemoveFromGroup() {
    return $(Padding).containing(find.text('Remove from group'));
  }

  PatrolFinder getLoadParticipantsLabel() {
    final loadMoreTextFinder = find.byWidgetPredicate(
      (w) =>
          w is Text &&
          RegExp(r'^Load\s+\d+\s+more\s+participant(s)?$')
              .hasMatch(w.data ?? ''),
      description: 'Load N more participants text',
    );

    return $(ListTile).containing(loadMoreTextFinder);
  }

  PatrolFinder getAgreeIRemoveMemberBtn() {
    return $(InkWell).containing(find.text('Remove'));
  }

  PatrolFinder getCancelRemoveMemberBtn() {
    return $(InkWell).containing(find.text('Cancel'));
  }

  String getTotalMemberLabel() {
    final a = $(find.textContaining('member')).text;
    return a!.replaceFirst(RegExp(r'\s+m.*$', caseSensitive: false), '');
  }

  Future<void> clickOnBackBtn() async {
    await getBackIcon().tap();
    await $.waitUntilVisible($(ChatView));
  }

  Future<void> clickOnRemoveFromGroup() async {
    await getcRemoveFromGroup().tap();
    await $.waitUntilVisible($(WarningDialogWidget));
  }

  Future<void> clickOnAgreeIRemoveMemberBtn() async {
    await getAgreeIRemoveMemberBtn().tap();
    await $.waitUntilVisible(getMemberTab());
  }

  Future<void> clickOnAddMemberBtn() async {
    await getAddMembersBtn().tap();
    await $.waitUntilVisible($(ContactsSelectionView));
  }

  Future<List<TwakeListItemRobot>> getListOfMembers() async {
    if (getLoadParticipantsLabel().exists) {
      await waitSnackGone($);
      await getLoadParticipantsLabel().tap();
      if ($(CircularProgressIndicator).exists) {
        await $.waitUntilVisible($(CircularProgressIndicator));
        await waitUntilAbsent($, $(CircularProgressIndicator));
      }
      await waitUntilAbsent($, getLoadParticipantsLabel());
    }

    final count = $(TwakeListItem).evaluate().length;
    return List.generate(
      count,
      (i) => TwakeListItemRobot($, $(TwakeListItem).at(i)),
    );
  }

  PatrolFinder getMemberByMatrixID(String matrixID) {
    return $(find.byKey(ValueKey<String>(matrixID)));
  }

  Future<void> openMemberDetail({
    required String matrixID,
  }) async {
    await $.scrollUntilVisible(finder: getMemberByMatrixID(matrixID));
    await getMemberByMatrixID(matrixID).tap();

    await $.waitUntilVisible($(ProfileInfoView));

    return;
  }
}
