import 'package:fluffychat/presentation/model/pop_result.dart';
import 'package:matrix/matrix.dart';

class PopResultFromForward extends PopResult {
  final Room roomReceiver;

  const PopResultFromForward({
    required this.roomReceiver,
  });
}
