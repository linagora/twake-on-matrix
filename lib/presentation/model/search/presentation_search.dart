import 'package:equatable/equatable.dart';
import 'package:fluffychat/domain/model/search/contact_search_model.dart';
import 'package:fluffychat/domain/model/search/recent_chat_model.dart';
import 'package:matrix/matrix.dart';

abstract class PresentationSearch extends Equatable {

  final String? displayName;

  String get id;

  @override
  bool? get stringify => true;

  const PresentationSearch({
    this.displayName,
  });
}

class ContactPresentationSearch extends PresentationSearch {

  final String? matrixId;

  final String? email;

  const ContactPresentationSearch(
      this.matrixId,
      this.email,
      {
        String? displayName,
      }
      ) : super(
    displayName: displayName,
  );

  @override
  String get id => matrixId ?? email ?? '';

  @override
  List<Object?> get props => [matrixId, email, displayName];
}

class RecentChatPresentationSearch extends PresentationSearch {

  final String? directChatMatrixID;

  final RoomSummary? roomSummary;

  const RecentChatPresentationSearch(
      this.directChatMatrixID,
      {
        this.roomSummary,
        String? displayName,
      }
      ) : super(
    displayName: displayName,
  );

  @override
  String get id => directChatMatrixID ?? '';

  @override
  List<Object?> get props => [directChatMatrixID, displayName, roomSummary];
}

extension RecentChatSearchModelExtension on RecentChatSearchModel {
  RecentChatPresentationSearch toPresentation() {
    return RecentChatPresentationSearch(
      id,
      displayName: displayName,
      roomSummary: roomSummary,
    );
  }
}

extension ContactSearchModelExtension on ContactSearchModel {
  ContactPresentationSearch toPresentation() {
    return ContactPresentationSearch(
      id,
      email,
      displayName: displayName,
    );
  }
}