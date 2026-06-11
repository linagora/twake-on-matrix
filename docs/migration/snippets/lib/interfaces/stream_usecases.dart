// domain/interfaces/stream_usecases.dart

import 'usecase_interfaces.dart';

/// Reactive use case without parameters
abstract class StreamUseCase<T> implements BaseUseCase<Stream<T>> {
  @override
  Stream<T> execute() => invoke();

  Stream<T> invoke();
}

/// Reactive use case with parameters
abstract class StreamUseCaseWithParams<T, P>
    implements BaseUseCaseWithParams<Stream<T>, P> {
  @override
  Stream<T> execute(P params) => invoke(params);

  Stream<T> invoke(P params);
}
