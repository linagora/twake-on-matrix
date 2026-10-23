/// Platform-agnostic contract for the app grid in the desktop top bar.
///
/// The grid only renders on web at desktop width; on mobile the button is
/// absent and [isAppGridButtonVisible] returns false.
abstract class AbstractAppGridRobot {
  bool isAppGridButtonVisible();
  bool isHelpButtonVisible();
  bool isAppGridOpen();
  List<String> getVisibleAppNames();
  List<String> getVisibleAppLinks();

  Future<void> openAppGrid();
  Future<void> closeAppGridByTappingButton();
  Future<void> closeAppGridByTappingOutside();
}
