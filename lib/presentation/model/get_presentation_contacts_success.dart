import 'package:fluffychat/app_state/success.dart';

class GetPresentationContactsSuccess<T> extends Success {
  final String keyword;
  final List<T> contacts;

  const GetPresentationContactsSuccess({
    required this.contacts,
    required this.keyword,
  });

  @override
  List<Object?> get props => [contacts, keyword];

  @override
  String toString() =>
      "GetPresentationContactsSuccess(): keyword: $keyword - contacts: ${contacts.length}";
}
