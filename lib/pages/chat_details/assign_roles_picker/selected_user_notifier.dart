import 'package:flutter/widgets.dart';
import 'package:matrix/matrix.dart';

class SelectedUsersMapChangeNotifier extends ChangeNotifier {
  final selectedUsersMap = <User, ValueNotifier<bool>>{};
  final haveSelectedUsersNotifier = ValueNotifier(false);
  Set<User> _selectedUsersList = {};

  Iterable<User> get usersList {
    return _selectedUsersList;
  }

  void onUserTileTap(BuildContext context, User user) {
    final oldVal = selectedUsersMap[user]?.value ?? false;
    final newVal = !oldVal;
    selectedUsersMap.putIfAbsent(user, () => ValueNotifier(newVal));
    selectedUsersMap[user]!.value = newVal;
    if (newVal) {
      _selectedUsersList.add(user);
    } else {
      _selectedUsersList.remove(user);
    }
    notifyListeners();
    haveSelectedUsersNotifier.value = usersList.isNotEmpty;
  }

  ValueNotifier<bool> getNotifierAtUser(User user) {
    selectedUsersMap.putIfAbsent(user, () => ValueNotifier(false));
    return selectedUsersMap[user]!;
  }

  void unselectUser(User user) {
    if (selectedUsersMap.containsKey(user)) {
      selectedUsersMap[user]!.value = false;
    }
    _selectedUsersList.remove(user);
    notifyListeners();
  }

  void unselectAllUsers() {
    for (final user in selectedUsersMap.keys) {
      selectedUsersMap[user]!.value = false;
    }
    _selectedUsersList = {};
    haveSelectedUsersNotifier.value = false;
    notifyListeners();
  }

  @override
  void dispose() {
    super.dispose();
    haveSelectedUsersNotifier.dispose();
  }
}
