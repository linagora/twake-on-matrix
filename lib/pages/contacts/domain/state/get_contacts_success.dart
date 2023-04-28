import 'package:fluffychat/entity/contact/contact.dart';
import 'package:fluffychat/state/success.dart';

class GetContactsSuccess extends Success {
  final Set<Contact> contacts;

  const GetContactsSuccess({required this.contacts});

  @override
  List<Object?> get props => [contacts];
}