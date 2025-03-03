import 'package:equatable/equatable.dart';

class TwakeLookupChunkException with EquatableMixin implements Exception {
  final String? message;

  TwakeLookupChunkException(this.message);

  @override
  List<Object?> get props => [message];
}
