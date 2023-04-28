// import 'package:dartz/dartz.dart';
// import 'package:fluffychat/domain/model/contact/contact.dart';
// import 'package:fluffychat/pages/contacts/domain/repository/local_contact_repository.dart';
// import 'package:fluffychat/domain/state/get_local_contact_failed.dart';
// import 'package:fluffychat/domain/state/get_local_contact_success.dart';
// import 'package:fluffychat/pages/contacts/presentation/extension/list_contact_extension.dart';
// import 'package:fluffychat/state/failure.dart';

// class GetLocalContactsInteractor {
//   final LocalContactRepository localContactRepository;

//   GetLocalContactsInteractor({required this.localContactRepository});

//   Stream<Either<Failure, GetLocalContactSuccess>> execute({
//     Set<Contact>? cacheContacts,
//     String? searchKey = ''
//   }) async* {
//     try {
//       if (cacheContacts != null) {
//         yield Right(GetLocalContactSuccess(contacts: cacheContacts
//           .filter(searchKey: searchKey)));
//         return ;
//       }

//       final localContacts = await localContactRepository.getContacts(withThumbnail: false);
//       yield Right(GetLocalContactSuccess(contacts: localContacts
//         .filter(searchKey: searchKey)));

//       final localContactsPhoto = await localContactRepository.getContacts(withThumbnail: true);
//       yield Right(GetLocalContactSuccess(contacts: localContactsPhoto
//         .filter(searchKey: searchKey)));
      
//     } catch(e) {
//       yield Left(GetLocalContactFailed(exception: e));
//     }
//   }
// }