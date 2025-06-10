import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/domain/model/room/room_extension.dart';
import 'package:fluffychat/pages/chat_details/assign_roles/assign_roles_view.dart';
import 'package:fluffychat/pages/chat_details/chat_details_edit_view_style.dart';
import 'package:fluffychat/pages/search/search_debouncer_mixin.dart';
import 'package:fluffychat/utils/responsive/responsive_utils.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';

class AssignRoles extends StatefulWidget {
  final Room room;

  const AssignRoles({
    super.key,
    required this.room,
  });

  @override
  AssignRolesController createState() => AssignRolesController();
}

class AssignRolesController extends State<AssignRoles>
    with SearchDebouncerMixin {
  final responsive = getIt.get<ResponsiveUtils>();

  final textEditingController = TextEditingController();

  final inputFocus = FocusNode();

  final ValueNotifier<List<User>> searchUserResults =
      ValueNotifier<List<User>>([]);

  void onBack() {
    Navigator.of(context).pop();
  }

  List<User> get assignRolesMember => widget.room.getAssignRolesMember();

  void handleSearchResults(String searchTerm) {
    if (searchTerm.isEmpty) {
      searchUserResults.value = [];
      return;
    }

    final assignedUsers = assignRolesMember;

    final searchResults = assignedUsers.where((user) {
      return (user.displayName ?? '')
              .toLowerCase()
              .contains(searchTerm.toLowerCase()) ||
          (user.id).toLowerCase().contains(searchTerm.toLowerCase());
    }).toList();

    Logs().d(
      "AssignRolesController::handleSearchResults: $searchTerm, results: ${searchResults.length}",
    );

    if (searchResults.isEmpty) {
      searchUserResults.value = [];
      return;
    }

    searchUserResults.value = searchResults;
  }

  @override
  void initState() {
    textEditingController.addListener(
      () => setDebouncerValue(textEditingController.text),
    );
    initializeDebouncer((searchTerm) {
      Logs().d("AssignRolesController::initState: $searchTerm");
      handleSearchResults(searchTerm);
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: ChatDetailEditViewStyle.fixedWidth,
      child: AssignRolesView(
        controller: this,
      ),
    );
  }
}
