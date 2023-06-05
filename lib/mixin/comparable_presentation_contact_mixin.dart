
import 'package:fluffychat/presentation/model/presentation_contact.dart';

class ComparablePresentationContactMixin {
  int comparePresentationContacts(PresentationContact contact1, PresentationContact contact2) {
    final buffer1 = StringBuffer();
    final buffer2 = StringBuffer();
    
    buffer1.writeAll([
      contact1.displayName ?? "",
      contact1.matrixId ?? "",
      contact1.email ?? "",
      contact1.status ?? "",
    ]);

    buffer2.writeAll([
      contact2.displayName ?? "",
      contact2.matrixId ?? "",
      contact2.email ?? "",
      contact2.status ?? "",
    ]);

    return buffer1.toString().compareTo(buffer2.toString());
  }
}