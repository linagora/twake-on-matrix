import 'package:fluffychat/app_state/initial.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/domain/model/contact/contact_v2.dart';

class GetPhonebookContactsInitial extends Initial {
  const GetPhonebookContactsInitial() : super();

  @override
  List<Object?> get props => [];
}

class GetPhonebookContactsLoading extends Success {
  final int progress;

  const GetPhonebookContactsLoading({required this.progress});

  @override
  List<Object?> get props => [progress];
}

class GetPhonebookContactsSuccess extends Success {
  final int progress;
  final int chunkSize;
  final int totalChunks;
  final List<Contact> foundContacts;
  final List<Contact> notFoundContacts;

  const GetPhonebookContactsSuccess({
    required this.progress,
    required this.chunkSize,
    required this.totalChunks,
    required this.foundContacts,
    required this.notFoundContacts,
  });

  @override
  List<Object?> get props => [
        progress,
        chunkSize,
        totalChunks,
        foundContacts,
        notFoundContacts,
      ];
}
