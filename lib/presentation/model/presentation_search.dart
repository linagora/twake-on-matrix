import 'package:equatable/equatable.dart';
import 'package:matrix/matrix.dart';

enum SearchTypeEnum {
  contact,
  recentChat,
}

class PresentationSearch extends Equatable {

  final String? email;

  final String? displayName;

  final String? matrixId;

  final SearchTypeEnum? searchTypeEnum;

  final RoomSummary? roomSummary;

  final String? directChatMatrixID;

  const PresentationSearch({
    this.email,
    this.displayName,
    this.matrixId,
    this.searchTypeEnum,
    this.roomSummary,
    this.directChatMatrixID
  });

  bool get isContact => searchTypeEnum == SearchTypeEnum.contact;

  @override
  List<Object?> get props => [
    email,
    displayName,
    matrixId,
    searchTypeEnum,
    roomSummary,
    directChatMatrixID
  ];
}