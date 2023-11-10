import 'package:equatable/equatable.dart';
import 'package:fluffychat/domain/contact_manager/contacts_manager.dart';
import 'package:fluffychat/domain/model/contact/contact.dart';

class ContactsManagerArguments extends Equatable {
  final Set<Contact> tomContacts;
  final DisplayWaringContactsBannerState displayWaringContactsBannerState;

  const ContactsManagerArguments({
    required this.tomContacts,
    this.displayWaringContactsBannerState =
        DisplayWaringContactsBannerState.show,
  });

  @override
  List<Object?> get props => [
        tomContacts,
        displayWaringContactsBannerState,
      ];
}
