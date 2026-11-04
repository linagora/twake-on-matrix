import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:twake_chat/data/account/repositories/account_repository_impl.provider.dart';
import 'package:twake_chat/domain/account/usecases/create_account_candidate_usecase.dart';

part 'create_account_candidate_usecase.provider.g.dart';

@riverpod
CreateAccountCandidateUseCase createAccountCandidateUseCase(Ref ref) =>
    CreateAccountCandidateUseCase(
      repository: ref.watch(accountRepositoryProvider),
    );
