import 'package:fluffychat/domain/model/contact/contact_type.dart';
import 'package:fluffychat/pages/new_private_chat/widget/expansion_contact_list_tile.dart';
import 'package:fluffychat/pages/search/search.dart';
import 'package:fluffychat/pages/search/search_external_contact_style.dart';
import 'package:fluffychat/presentation/model/contact/presentation_contact.dart';
import 'package:fluffychat/presentation/model/search/presentation_search.dart';
import 'package:flutter/material.dart' hide SearchController;

class SearchExternalContactWidget extends StatelessWidget {
  const SearchExternalContactWidget({
    super.key,
    required this.keyword,
    required this.searchController,
  });

  final String keyword;
  final SearchController searchController;

  @override
  Widget build(BuildContext context) {
    final newContact = PresentationContact(
      matrixId: keyword,
      displayName: keyword.substring(1),
      type: ContactType.external,
    );

    return Padding(
      padding: SearchExternalContactStyle.contentPadding,
      child: InkWell(
        onTap: () {
          searchController.onSearchItemTap(
            ContactPresentationSearch(
              matrixId: newContact.matrixId,
              email: newContact.email,
              displayName: newContact.displayName,
            ),
          );
        },
        borderRadius: SearchExternalContactStyle.borderRadius,
        child: ExpansionContactListTile(
          contact: newContact,
          highlightKeyword: searchController.textEditingController.text,
        ),
      ),
    );
  }
}
