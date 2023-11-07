import 'package:fluffychat/app_state/success.dart';

abstract class LazyLoadSuccess<T> extends Success {
  final List<T> tomContacts;
  final List<T>? phonebookContacts;

  const LazyLoadSuccess({
    required this.tomContacts,
    this.phonebookContacts,
  });

  @override
  List<Object?> get props => [tomContacts, phonebookContacts];
}
