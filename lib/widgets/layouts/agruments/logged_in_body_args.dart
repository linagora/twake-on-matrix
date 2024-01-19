import 'package:fluffychat/widgets/layouts/agruments/app_adaptive_scaffold_body_args.dart';

class LoggedInBodyArgs extends AbsAppAdaptiveScaffoldBodyArgs {
  final String? roomIdFromNoti;

  const LoggedInBodyArgs({
    required super.newActiveClient,
    this.roomIdFromNoti,
  });

  @override
  List<Object?> get props => [
        newActiveClient,
        roomIdFromNoti,
      ];
}
