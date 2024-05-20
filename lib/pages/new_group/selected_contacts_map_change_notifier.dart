import 'package:fluffychat/presentation/model/contact/presentation_contact.dart';
import 'package:flutter/widgets.dart';

class SelectedContactsMapChangeNotifier extends ChangeNotifier {
  final selectedContactsMap = <PresentationContact, ValueNotifier<bool>>{};
  final haveSelectedContactsNotifier = ValueNotifier(false);
  Set<PresentationContact> _selectedContactsList = {};

  Iterable<PresentationContact> get contactsList {
    return _selectedContactsList;
  }

  void onContactTileTap(BuildContext context, PresentationContact contact) {
    final oldVal = selectedContactsMap[contact]?.value ?? false;
    final newVal = !oldVal;
    selectedContactsMap.putIfAbsent(contact, () => ValueNotifier(newVal));
    selectedContactsMap[contact]!.value = newVal;
    if (newVal) {
      _selectedContactsList.add(contact);
    } else {
      _selectedContactsList.remove(contact);
    }
    notifyListeners();
    haveSelectedContactsNotifier.value = contactsList.isNotEmpty;
  }

  ValueNotifier<bool> getNotifierAtContact(PresentationContact contact) {
    selectedContactsMap.putIfAbsent(contact, () => ValueNotifier(false));
    return selectedContactsMap[contact]!;
  }

  void unselectContact(PresentationContact contact) {
    if (selectedContactsMap.containsKey(contact)) {
      selectedContactsMap[contact]!.value = false;
    }
    _selectedContactsList.remove(contact);
    notifyListeners();
  }

  void unselectAllContacts() {
    for (final contact in selectedContactsMap.keys) {
      selectedContactsMap[contact]!.value = false;
    }
    _selectedContactsList = {};
    haveSelectedContactsNotifier.value = false;
    notifyListeners();
  }

  @override
  void dispose() {
    super.dispose();
    haveSelectedContactsNotifier.dispose();
  }
}
