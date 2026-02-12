import 'package:dartz/dartz.dart';
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/modules/federation_identity_request_token/domain/repository/federation_identity_request_token_repository.dart';
import 'package:fluffychat/modules/federation_identity_request_token/domain/state/federation_identity_request_token_state.dart';

class FederationIdentityRequestTokenInteractor {
  final FederationIdentityRequestTokenRepository repository;

  FederationIdentityRequestTokenInteractor({required this.repository});

  Future<Either<Failure, Success>> execute({required String mxid}) async {
    try {
      final response = await repository.requestToken(mxid: mxid);
      return Right(
        FederationIdentityRequestTokenSuccess(tokenInformation: response),
      );
    } catch (e) {
      return Left(FederationIdentityRequestTokenFailure(exception: e));
    }
  }
}
