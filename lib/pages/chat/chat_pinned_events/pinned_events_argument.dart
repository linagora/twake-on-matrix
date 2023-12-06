import 'package:equatable/equatable.dart';
import 'package:matrix/matrix.dart';

class PinnedEventsArgument with EquatableMixin {
  final List<Event?> pinnedEvents;

  final Timeline? timeline;

  PinnedEventsArgument({required this.pinnedEvents, this.timeline});

  @override
  List<Object?> get props => [pinnedEvents, timeline];
}
