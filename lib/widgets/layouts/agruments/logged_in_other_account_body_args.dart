import 'package:fluffychat/widgets/layouts/agruments/app_adaptive_scaffold_body_args.dart';

class LoggedInOtherAccountBodyArgs extends AbsAppAdaptiveScaffoldBodyArgs {
  const LoggedInOtherAccountBodyArgs({
    required super.newActiveClient,
  });

  @override
  List<Object?> get props => [
        newActiveClient,
      ];
}
