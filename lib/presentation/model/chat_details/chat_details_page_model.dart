import 'package:equatable/equatable.dart';
import 'package:fluffychat/pages/chat_details/chat_details_page_view/chat_details_page_enum.dart';
import 'package:flutter/material.dart';

class ChatDetailsPageModel extends Equatable {
  final ChatDetailsPage page;
  final Widget child;

  const ChatDetailsPageModel({
    required this.page,
    required this.child,
  });
  @override
  List<Object?> get props => [
        page,
        child,
      ];
}
