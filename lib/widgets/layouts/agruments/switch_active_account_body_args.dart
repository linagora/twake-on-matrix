import 'package:fluffychat/widgets/layouts/agruments/app_adaptive_scaffold_body_args.dart';

class SwitchActiveAccountBodyArgs extends AbsAppAdaptiveScaffoldBodyArgs {
  const SwitchActiveAccountBodyArgs({
    required super.newActiveClient,
  });

  @override
  List<Object?> get props => [
        newActiveClient,
      ];
}
