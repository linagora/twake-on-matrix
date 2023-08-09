import 'package:equatable/equatable.dart';

class RecoveryWords with EquatableMixin {
  final String words;

  RecoveryWords(this.words);

  @override
  List<Object?> get props => [words];
}
