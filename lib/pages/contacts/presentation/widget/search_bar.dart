import 'package:fluffychat/pages/contacts/presentation/contacts_picker.dart';
import 'package:flutter/material.dart';

typedef OnSearchBarChanged = void Function(String searchKeyword);

class SearchBar extends StatefulWidget {
  final ContactsPickerController contactsPickerController;

  const SearchBar({
    Key? key,
    required this.contactsPickerController
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _SearchBarState();
}

class _SearchBarState extends State<SearchBar> {
  late final TextEditingController textEditingController;

  @override
  void initState() {
    super.initState();
    textEditingController = TextEditingController();
    textEditingController.addListener(() {
      widget.contactsPickerController.onSearchBarChanged(textEditingController.text);
    });
  }

  @override
  void dispose() {
    super.dispose();
    textEditingController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: textEditingController,
      decoration: InputDecoration(
        hintText: 'Search'
      ),
    );
  }

}