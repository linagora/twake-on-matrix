import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:twake_chat/pages/chat/chat_view.dart';
import 'package:twake_chat/pages/chat_details/chat_details_edit_view.dart';
import 'package:twake_chat/pages/chat_details/chat_details_group_description_view.dart';
import 'package:twake_chat/pages/chat_details/chat_details_view.dart';
import 'package:twake_chat/pages/chat_details/participant_list_item/mobile_context_menu_overlay.dart';
import 'package:twake_chat/pages/new_group/contacts_selection_view.dart';
import 'package:twake_chat/pages/profile_info/profile_info_view.dart';
import 'package:twake_chat/utils/warning_dialog.dart';
import 'package:twake_chat/widgets/twake_components/twake_icon_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';
import 'package:patrol/patrol.dart';
import '../base/core_robot.dart';
import 'abstract/abstract_group_information_robot.dart';
import 'add_member_robot.dart';
import 'twake_list_item_robot.dart';

const _serverTimeout = Duration(seconds: 30);

class GroupInformationRobot extends CoreRobot
    implements AbstractGroupInformationRobot {
  GroupInformationRobot(super.$);

  L10n get _l10n => L10n.of($.tester.element(find.byType(Scaffold).last))!;

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
    return $(Tab).containing(find.text(_l10n.links));
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
          RegExp(
            r'^Load\s+\d+\s+more\s+participant(s)?$',
          ).hasMatch(w.data ?? ''),
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
    await goBack();
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
    final List<TwakeListItemRobot> groupList = [];

    final matches = $(TwakeListItem).evaluate();
    for (final element in matches) {
      final finder = $(element.widget.runtimeType);
      groupList.add(TwakeListItemRobot($, finder));
    }
    return groupList;
  }

  PatrolFinder getMemberByMatrixID(String matrixID) {
    return $(find.byKey(ValueKey<String>(matrixID)));
  }

  @override
  Future<void> openMemberDetail({required String matrixID}) async {
    await $.scrollUntilVisible(finder: getMemberByMatrixID(matrixID));
    await getMemberByMatrixID(matrixID).tap();

    await $.waitUntilVisible($(ProfileInfoView));

    return;
  }

  PatrolFinder get _editButton =>
      $(ChatDetailsView).$(TextButton).containing(find.text(_l10n.edit));

  PatrolFinder get _saveButton =>
      $(ChatDetailsEditView).$(IconButton).containing(find.byIcon(Icons.done));

  PatrolFinder _editField(String label) =>
      $(find.widgetWithText(TextField, label));

  PatrolFinder muteAction({required bool muted}) => $(
    ChatDetailsView,
  ).$(InkWell).containing(find.text(muted ? _l10n.unmute : _l10n.mute));

  PatrolFinder description(String text) =>
      $(ChatDetailsGroupDescriptionView).$(find.text(text));

  PatrolFinder headerTitle(String name) => $(ChatDetailsView).$(name);

  Future<void> openEdit() async {
    await _editButton.tap();
    await $.waitUntilVisible($(ChatDetailsEditView));
  }

  Future<void> saveGroupInfo({
    required String name,
    required String description,
  }) async {
    await _editField(_l10n.groupName).enterText(name);
    await _editField(_l10n.description).enterText(description);
    await _saveButton.tap();
    await waitUntilAbsent($, _saveButton, timeout: _serverTimeout);
    await $.pumpAndTrySettle();
  }

  Future<void> closeEdit() async {
    await $(ChatDetailsEditView).$(find.byIcon(Icons.arrow_back_ios)).tap();
    await $.waitUntilVisible($(ChatDetailsView));
  }

  Future<void> toggleMute({required bool muted}) async {
    await muteAction(muted: muted).tap();
    await $.waitUntilVisible(
      muteAction(muted: !muted),
      timeout: _serverTimeout,
    );
  }

  Future<void> inviteMember(String searchKey) async {
    await getAddMembersBtn().tap();
    await $.waitUntilVisible($(ContactsSelectionView));
    final addMember = AddMemberRobot($);
    await addMember.makeASearch(searchKey);
    await addMember.selectAllFilteredAccounts();
    await addMember.getNextIcon().tap();
    await $.waitUntilVisible($(ChatDetailsView));
  }

  Future<void> expectMember(String matrixID) => $.waitUntilVisible(
    getMemberByMatrixID(matrixID),
    timeout: _serverTimeout,
  );

  Future<void> removeMember(String matrixID) async {
    await expectMember(matrixID);
    await getMemberByMatrixID(matrixID).longPress();
    // The menu is pushed on its own route, above the overlay.
    await $.waitUntilExists($(MobileContextMenuOverlay));
    final remove = $(_l10n.removeFromGroup).last;
    await $.waitUntilVisible(remove);
    await remove.tap();
    await waitUntilAbsent(
      $,
      getMemberByMatrixID(matrixID),
      timeout: _serverTimeout,
    );
  }
}
