import 'package:twake_chat/widgets/layouts/agruments/app_adaptive_scaffold_body_args.dart';
import 'package:twake_chat/widgets/layouts/enum/adaptive_destinations_enum.dart';

class ReceiveContentArgs extends AbsAppAdaptiveScaffoldBodyArgs {
  const ReceiveContentArgs({
    required super.newActiveClient,
    this.activeDestination,
  });

  final AdaptiveDestinationEnum? activeDestination;

  @override
  List<Object?> get props => [newActiveClient, activeDestination];
}
