import 'package:equatable/equatable.dart';

class MessageMetrics extends Equatable {
  final double totalMessageWidth;
  final bool isNeedAddNewLine;

  const MessageMetrics({
    required this.totalMessageWidth,
    required this.isNeedAddNewLine,
  });

  @override
  List<Object?> get props => [
        totalMessageWidth,
        isNeedAddNewLine,
      ];
}
