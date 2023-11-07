import 'package:fluffychat/domain/model/contact/contact.dart';
import 'package:fluffychat/domain/model/search/contact_search_model.dart';
import 'package:fluffychat/domain/model/search/search_model.dart';

extension ContactExtension on Contact {
  Set<SearchModel> toSearch() {
    final listContacts = {
      ContactSearchModel(
        matrixId,
        email,
        displayName: displayName,
      ),
    };

    if (email == null || email!.isEmpty) {
      listContacts.add(
        ContactSearchModel(
          matrixId,
          null,
          displayName: displayName,
        ),
      );
    }

    return listContacts;
  }
}
