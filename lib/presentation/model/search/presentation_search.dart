import 'package:equatable/equatable.dart';
import 'package:fluffychat/domain/model/search/contact_search_model.dart';
import 'package:fluffychat/domain/model/search/recent_chat_model.dart';
import 'package:matrix/matrix.dart';

abstract class PresentationSearch extends Equatable {
  final String? displayName;

  final String? directChatMatrixID;

  String get id;

  @override
  bool? get stringify => true;

  const PresentationSearch({
    this.displayName,
    this.directChatMatrixID,
  });
}

class ContactPresentationSearch extends PresentationSearch {
  final String? matrixId;
  final String? email;

  const ContactPresentationSearch({
    this.matrixId,
    this.email,
    String? displayName,
  }) : super(
          displayName: displayName,
        );

  @override
  String get id => matrixId ?? email ?? '';

  @override
  List<Object?> get props => [matrixId, email, displayName];
}

class RecentChatPresentationSearch extends PresentationSearch {
  final String? roomId;

  final RoomSummary? roomSummary;

  const RecentChatPresentationSearch({
    this.roomId,
    this.roomSummary,
    String? displayName,
    String? directChatMatrixID,
  }) : super(
          displayName: displayName,
          directChatMatrixID: directChatMatrixID,
        );

  @override
  String get id => roomId ?? '';

  @override
  List<Object?> get props =>
      [roomId, displayName, roomSummary, directChatMatrixID];
}

extension RecentChatSearchModelExtension on RecentChatSearchModel {
  RecentChatPresentationSearch toPresentation() {
    return RecentChatPresentationSearch(
      roomId: id,
      displayName: displayName,
      roomSummary: roomSummary,
      directChatMatrixID: directChatMatrixID,
    );
  }
}

extension ContactSearchModelExtension on ContactSearchModel {
  ContactPresentationSearch toPresentation() {
    return ContactPresentationSearch(
      matrixId: id,
      email: email,
      displayName: displayName,
    );
  }
}

extension UserExtension on User {
  ContactPresentationSearch toContactPresentationSearch() {
    return ContactPresentationSearch(
      matrixId: id,
      displayName: displayName,
    );
  }
}
