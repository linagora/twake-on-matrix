// domain/interfaces/usecase_interfaces.dart

/// Abstract interface for base use case
// ignore_for_file: one_member_abstracts
abstract interface class BaseUseCase<R> {
  R execute();
}

/// Abstract interface for base use case with params
abstract interface class BaseUseCaseWithParams<R, P> {
  R execute(P params);
}
