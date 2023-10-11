import 'package:equatable/equatable.dart';
import 'package:flutter/services.dart';

class ClipboardImageInfo with EquatableMixin {
  final Stream<Uint8List> stream;

  final String? fileName;

  final int? fileSize;

  ClipboardImageInfo({
    required this.stream,
    this.fileName,
    this.fileSize,
  });

  @override
  List<Object?> get props => [stream, fileName, fileSize];
}
