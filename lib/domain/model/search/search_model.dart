import 'package:equatable/equatable.dart';

abstract class SearchModel extends Equatable {
  final String? displayName;

  final String? directChatMatrixID;

  String get id;

  const SearchModel({
    this.directChatMatrixID,
    this.displayName,
  });
}
