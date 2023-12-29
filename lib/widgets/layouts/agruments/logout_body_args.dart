import 'package:fluffychat/widgets/layouts/agruments/app_adaptive_scaffold_body_args.dart';

class LogoutBodyArgs extends AbsAppAdaptiveScaffoldBodyArgs {
  const LogoutBodyArgs({
    required super.newActiveClient,
  });

  @override
  List<Object?> get props => [
        newActiveClient,
      ];
}
