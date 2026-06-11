// domain/interfaces/future_usecases.dart

import 'usecase_interfaces.dart';

/// Async use case without parameters
abstract class FutureUseCase<T> implements BaseUseCase<Future<T>> {
  const FutureUseCase();
  @override
  Future<T> execute() => invoke();

  Future<T> invoke();
}

/// Async use case with parameters
abstract class FutureUseCaseWithParams<T, P>
    implements BaseUseCaseWithParams<Future<T>, P> {
  const FutureUseCaseWithParams();
  @override
  Future<T> execute(P params) => invoke(params);

  Future<T> invoke(P params);
}
