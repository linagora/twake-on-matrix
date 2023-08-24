import 'package:fluffychat/presentation/model/presentation_contact.dart';
import 'package:flutter/widgets.dart';

class SelectedContactsMapChangeNotifier extends ChangeNotifier {
  final Map<PresentationContact, ValueNotifier<bool>> selectedContactsMap = {};
  final haveSelectedContactsNotifier = ValueNotifier(false);

  Iterable<PresentationContact> get contactsList => selectedContactsMap.keys
      .where((contact) => selectedContactsMap[contact]?.value ?? false);

  void onContactTileTap(BuildContext context, PresentationContact contact) {
    final oldVal = selectedContactsMap[contact]?.value ?? false;
    final newVal = !oldVal;
    selectedContactsMap.putIfAbsent(contact, () => ValueNotifier(newVal));
    selectedContactsMap[contact]!.value = newVal;
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
    notifyListeners();
  }

  @override
  void dispose() {
    super.dispose();
    haveSelectedContactsNotifier.dispose();
  }
}
