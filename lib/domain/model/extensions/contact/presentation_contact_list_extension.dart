import 'package:fluffychat/domain/model/extensions/contact/presentation_contact_extension.dart';
import 'package:fluffychat/presentation/model/presentation_contact.dart';
import 'package:fluffychat/presentation/model/presentation_search.dart';

extension PresentaionContactListExtension on List<PresentationContact> {
  List<PresentationSearch> toPresentationSearchList() {
    return map((contact) => contact.toPresentationSearch()).toList();
  }
}