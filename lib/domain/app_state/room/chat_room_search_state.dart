import 'package:dartz/dartz.dart';

import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/initial.dart';
import 'package:fluffychat/app_state/success.dart';

class ChatRoomSearchInitial extends Initial {
  @override
  List<Object?> get props => [];
}

class ChatRoomSearchLoading extends Success {
  @override
  List<Object?> get props => [];
}

class ChatRoomSearchSuccess extends Success {
  final String keyword;
  final int eventIndex;

  const ChatRoomSearchSuccess({
    required this.keyword,
    required this.eventIndex,
  });

  @override
  List<Object?> get props => [keyword, eventIndex];
}

class ChatRoomSearchNoResult extends Failure {
  @override
  List<Object?> get props => [];
}

class ChatRoomSearchFailure extends Failure {
  final dynamic exception;

  const ChatRoomSearchFailure({required this.exception});

  @override
  List<Object?> get props => [exception];
}

extension ChatRoomSearchEitherExtension on Either {
  ChatRoomSearchSuccess? getSuccessOrNull() => fold(
        (failure) => null,
        (success) => success is ChatRoomSearchSuccess ? success : null,
      );
}
