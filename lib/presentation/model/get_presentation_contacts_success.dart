import 'package:equatable/equatable.dart';

class GetPresentationContactsSuccess<T> extends Equatable {
  final String keyword;
  final List<T> tomContacts;
  final List<T>? phonebookContacts;

  const GetPresentationContactsSuccess({
    required this.tomContacts,
    this.phonebookContacts,
    required this.keyword,
  });

  @override
  List<Object?> get props => [tomContacts, phonebookContacts, keyword];

  @override
  String toString() =>
      "GetPresentationContactsSuccess(): tomContacts: ${tomContacts.length} - phonebookContacts: $phonebookContacts - keyword: $keyword";
}
