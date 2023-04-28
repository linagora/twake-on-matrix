import 'package:fluffychat/domain/model/contact/tom_contact.dart';
import 'package:json_annotation/json_annotation.dart';

class TomContactConverter extends JsonConverter<TomContact, Map<String, String>> {
  @override
  fromJson(json) {
    return TomContact(mxid: json['uid']!, mail: json['mail']!);
  }

  @override
  toJson(object) {
    return {
      'uid': object.mxid,
      'mail': object.mail
    };
  }

}