import 'package:dartz/dartz.dart';
import 'package:twake_chat/app_state/failure.dart';
import 'package:twake_chat/app_state/success.dart';
import 'package:twake_chat/di/global/get_it_initializer.dart';
import 'package:twake_chat/domain/app_state/contact/delete_third_party_contact_box_state.dart';
import 'package:twake_chat/domain/repository/contact/hive_contact_repository.dart';
import 'package:matrix/matrix.dart';

class DeleteThirdPartyContactBoxInteractor {
  final HiveContactRepository _hiveContactRepository = getIt
      .get<HiveContactRepository>();

  DeleteThirdPartyContactBoxInteractor();

  Stream<Either<Failure, Success>> execute() async* {
    try {
      yield const Right(DeleteThirdPartyContactBoxLoading());
      await _hiveContactRepository.deleteThirdPartyContactBox();

      yield const Right(DeleteThirdPartyContactBoxSuccessState());
    } catch (e) {
      Logs().e('DeleteThirdPartyContactBoxInteractor::execute', e);
      yield Left(DeleteThirdPartyContactBoxFailureState(exception: e));
    }
  }
}
