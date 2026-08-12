import 'package:dartz/dartz.dart';
import 'package:twake_chat/app_state/failure.dart';
import 'package:twake_chat/app_state/success.dart';
import 'package:twake_chat/di/global/get_it_initializer.dart';
import 'package:twake_chat/domain/app_state/capabilities/get_server_capabilities_state.dart';
import 'package:twake_chat/domain/repository/capabilities/server_capabilities_repository.dart';
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
