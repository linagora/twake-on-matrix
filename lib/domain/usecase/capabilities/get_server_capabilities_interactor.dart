import 'package:dartz/dartz.dart';
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/domain/app_state/capabilities/get_server_capabilities_state.dart';
import 'package:fluffychat/domain/repository/capabilities/server_capabilities_repository.dart';
import 'package:matrix/matrix.dart';

class GetServerCapabilitiesInteractor {
  const GetServerCapabilitiesInteractor();

  Stream<Either<Failure, Success>> execute() async* {
    try {
      yield Right(GettingServerCapabilities());
      final response = await getIt
          .get<ServerCapabilitiesRepository>()
          .getCapabilities();
      Logs().d(
        'GetServerCapabilitiesInteractor::execute(): response - $response',
      );
      yield Right(GetServerCapabilitiesSuccess(response));
    } catch (e) {
      Logs().e('GetServerCapabilitiesInteractor::execute(): Exception - $e');
      yield Left(GetServerCapabilitiesFailure(exception: e));
    }
  }
}
