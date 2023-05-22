import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/domain/model/contact/contact.dart';

class GetContactsSuccess extends Success {
  final Set<Contact> contacts;

  const GetContactsSuccess({required this.contacts});

  @override
  List<Object?> get props => [contacts];
}