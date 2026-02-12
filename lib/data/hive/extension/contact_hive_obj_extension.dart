import 'package:fluffychat/data/hive/dto/contact/contact_hive_obj.dart';
import 'package:fluffychat/data/hive/dto/contact/third_party_contact_hive_obj.dart';
import 'package:fluffychat/domain/model/contact/contact.dart';

extension ContactHiveObjExtension on ContactHiveObj {
  Contact toContact() {
    return Contact(
      id: id,
      displayName: displayName,
      emails: emails?.map((email) => email.toEmail()).toSet(),
      phoneNumbers: phoneNumbers?.map((phone) => phone.toPhoneNumber()).toSet(),
    );
  }
}

extension PhoneNumberHiveObjectExtension on PhoneNumberHiveObject {
  PhoneNumber toPhoneNumber() {
    return PhoneNumber(number: number, matrixId: matrixId);
  }
}

extension EmailHiveObjectExtension on EmailHiveObject {
  Email toEmail() {
    return Email(address: email, matrixId: matrixId);
  }
}
