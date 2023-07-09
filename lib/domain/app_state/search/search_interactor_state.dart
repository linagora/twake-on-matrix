import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/presentation/model/presentation_search.dart';

class GetContactAndRecentChatSuccess extends Success {
  final List<PresentationSearch> presentationSearches;

  const GetContactAndRecentChatSuccess({required this.presentationSearches});

  @override
  List<Object?> get props => [presentationSearches];
}

class GetContactAndRecentChatFailed extends Failure {

  final dynamic exception;

  const GetContactAndRecentChatFailed({required this.exception});

  @override
  List<Object?> get props => [exception];

}