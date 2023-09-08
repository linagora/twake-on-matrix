import 'package:dartz/dartz.dart';
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/config/app_config.dart';
import 'package:fluffychat/domain/app_state/room/chat_room_search_state.dart';
import 'package:fluffychat/utils/string_extension.dart';
import 'package:matrix/matrix.dart';

class ChatRoomSearchInteractor {
  Stream<Either<Failure, Success>> execute({
    required Timeline timeline,
    required String keyword,
    required int currentEventIndex,
    required Direction direction,
    required int limitPerRequest,
    required int maxRequest,
  }) async* {
    try {
      if (keyword.length < AppConfig.chatRoomSearchKeywordMin) {
        yield Right(ChatRoomSearchInitial());
        return;
      }
      yield Right(ChatRoomSearchLoading());
      final bool Function(Event)? searchFunc;
      if (AppConfig.chatRoomSearchWordStrategy) {
        searchFunc = (event) => event.plaintextBody.containsWord(keyword);
      } else {
        final lowerCaseKeyword = keyword.toLowerCase();
        searchFunc = (event) =>
            event.plaintextBody.toLowerCase().contains(lowerCaseKeyword);
      }
      switch (direction) {
        case Direction.b:
          for (var i = 0; i < maxRequest; i++) {
            final index = timeline.events
                .sublist(currentEventIndex + 1)
                .indexWhere(searchFunc);
            if (index >= 0) {
              yield Right(
                ChatRoomSearchSuccess(
                  keyword: keyword,
                  eventIndex: currentEventIndex + 1 + index,
                ),
              );
              return;
            }
            if (timeline.canRequestHistory) {
              currentEventIndex = timeline.events.length;
              await timeline.requestHistory(historyCount: limitPerRequest);
            }
          }
          break;

        case Direction.f:
          final index = timeline.events
              .sublist(0, currentEventIndex)
              .lastIndexWhere(searchFunc);
          if (index >= 0) {
            yield Right(
              ChatRoomSearchSuccess(keyword: keyword, eventIndex: index),
            );
            return;
          }
          break;
      }
      yield Left(ChatRoomSearchNoResult());
    } catch (exception) {
      yield Left(ChatRoomSearchFailure(exception: exception));
    }
  }
}
