import 'package:equatable/equatable.dart';

abstract class SearchModel extends Equatable {

  final String? displayName;

  String get id;

  const SearchModel({
    this.displayName,
  });
}