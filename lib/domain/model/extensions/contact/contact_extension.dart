import 'package:fluffychat/domain/model/contact/contact.dart';
import 'package:fluffychat/domain/model/search/search_model.dart';
import 'package:fluffychat/presentation/model/presentation_contact.dart';

extension ContactExtension on Contact {
  Set<PresentationContact> toPresentationContacts() {
    final listContacts = emails?.map((email) => PresentationContact(
      email: email,
      displayName: displayName,
      matrixId: matrixId,
      status: status,
    )).toSet() ?? {};

    if (emails == null || emails!.isEmpty) {
      listContacts.add(PresentationContact(
        email: null,
        displayName: displayName,
        matrixId: matrixId,
        status: status,
      ));
    }

    return listContacts;
  }

  Set<SearchModel> toSearch() {
    final listContacts = emails?.map((email) => SearchModel(
      email: email,
      displayName: displayName,
      matrixId: matrixId,
    )).toSet() ?? {};

    if (emails == null || emails!.isEmpty) {
      listContacts.add(SearchModel(
        email: null,
        displayName: displayName,
        matrixId: matrixId,
      ));
    }

    return listContacts;
  }
}