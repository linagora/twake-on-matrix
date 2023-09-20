import 'package:equatable/equatable.dart';

enum SelectionType {
  selected,
  unselected,
}

class ConversationSelectionPresentation extends Equatable {
  final String roomId;
  final SelectionType selectionType;

  const ConversationSelectionPresentation({
    required this.roomId,
    this.selectionType = SelectionType.unselected,
  });

  bool get isSelected => selectionType == SelectionType.selected;

  @override
  List<Object?> get props => [roomId, selectionType];
}
