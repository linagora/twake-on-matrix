import 'package:equatable/equatable.dart';
import 'package:matrix/matrix.dart';

abstract class AbsAppAdaptiveScaffoldBodyArgs with EquatableMixin {
  final Client? newActiveClient;

  const AbsAppAdaptiveScaffoldBodyArgs({required this.newActiveClient});
  @override
  List<Object?> get props => [newActiveClient];
}
