/// Platform-agnostic contract for the group-information screen.
abstract class AbstractGroupInformationRobot {
  /// Scrolls the member list until the participant identified by
  /// [matrixID] is visible, taps it and waits for the profile view.
  Future<void> openMemberDetail({required String matrixID});
}
