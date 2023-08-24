import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/utils/responsive/responsive_utils.dart';

class ChatListHeaderStyle {
  static ResponsiveUtils responsive = getIt.get<ResponsiveUtils>();

  static const double searchRadiusBorder = 24.0;
  static const double searchBarContainerHeight = 64.0;
}
