import 'package:equatable/equatable.dart';
import 'package:matrix/matrix.dart';

abstract class AbsAppAdaptiveScaffoldBodyArgs extends Equatable {
  final Client? newActiveClient;

  const AbsAppAdaptiveScaffoldBodyArgs({
    required this.newActiveClient,
  });
  @override
  List<Object?> get props => [
        newActiveClient,
      ];
}
