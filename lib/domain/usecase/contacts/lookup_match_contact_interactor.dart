import 'package:dartz/dartz.dart';
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/domain/app_state/contact/lookup_match_contact_state.dart';
import 'package:fluffychat/domain/model/contact/contact_query.dart';
import 'package:fluffychat/domain/model/contact/lookup_mxid_request.dart';
import 'package:fluffychat/domain/repository/contact_repository.dart';
import 'package:matrix/matrix.dart';

class LookupMatchContactInteractor {
  final ContactRepository contactRepository = getIt.get<ContactRepository>();

  LookupMatchContactInteractor();

  Stream<Either<Failure, Success>> execute({
    required String val,
  }) async* {
    try {
      yield const Right(LookupContactsLoading());
      Logs().i('LookupMatchContactInteractor:: Loading...');
      final contactMatched = await contactRepository.lookupMatchContact(
        query: ContactQuery(keyword: val),
        lookupMxidRequest: LookupMxidRequest(
          scope: [
            'mail',
            'uid',
            'mobile',
            'cn',
            'displayName',
            'sn',
            'matrixAddress',
          ],
          fields: ['uid', 'mobile', 'mail', 'cn', 'displayName'],
          val: val,
        ),
      );
      if (contactMatched.isEmpty) {
        Logs().i('LookupMatchContactInteractor:: contactMatched is empty');
        yield const Right(LookupContactsEmpty());
      } else {
        Logs().i(
          'LookupMatchContactInteractor:: contactMatched ${contactMatched.first}',
        );
        yield Right(
          LookupMatchContactSuccess(contact: contactMatched.first),
        );
      }
    } catch (e) {
      Logs().e('LookupMatchContactInteractor:: Error $e');
      yield Left(LookupContactsFailure(keyword: val, exception: e));
    }
  }
}
