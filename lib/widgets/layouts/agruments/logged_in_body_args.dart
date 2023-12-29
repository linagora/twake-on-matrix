import 'package:fluffychat/widgets/layouts/agruments/app_adaptive_scaffold_body_args.dart';

class LoggedInBodyArgs extends AbsAppAdaptiveScaffoldBodyArgs {
  const LoggedInBodyArgs({
    required super.newActiveClient,
  });

  @override
  List<Object?> get props => [
        newActiveClient,
      ];
}
