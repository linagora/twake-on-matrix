import 'package:fluffychat/app_state/lazy_load_success.dart';

class GetPresentationContactsSuccess<T> extends LazyLoadSuccess<T> {
  final String keyword;

  const GetPresentationContactsSuccess({
    required super.tomContacts,
    super.phonebookContacts,
    required this.keyword,
  });

  @override
  List<Object?> get props => [tomContacts, phonebookContacts, keyword];

  @override
  String toString() =>
      "PresentaionSearchableSuccess tomContacts: ${tomContacts.length} - phonebookContacts: $phonebookContacts - keyword: $keyword";
}
