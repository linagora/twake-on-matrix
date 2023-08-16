import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/app_state/success_converter.dart';
import 'package:fluffychat/domain/app_state/contact/get_contacts_state.dart';
import 'package:fluffychat/presentation/extensions/contact/presentation_contact_extension.dart';
import 'package:fluffychat/presentation/model/presentation_contact_success.dart';

class PresentationContactConverter implements SuccessConverter {
  @override
  Success convert(Success success) {
    if (success is GetContactsSuccess) {
      return PresentationContactsSuccess(
        data: success.data.expand((e) => e.toPresentationContacts()).toList(),
        offset: success.offset,
        isEnd: success.isEnd,
        keyword: success.keyword,
      );
    }
    return success;
  }
}
