/// Platform-agnostic contract for the contacts-list screen.
///
/// Thin interface — the concrete robot mostly wraps `TwakeListItem`
/// finders which are platform-independent today. The contract exists so
/// `RobotFactory.contactListRobot()` has a return type and web
/// implementations can override list-item resolution if needed later.
abstract class AbstractContactListRobot {}
