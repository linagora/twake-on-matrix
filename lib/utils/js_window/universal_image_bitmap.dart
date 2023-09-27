import 'package:equatable/equatable.dart';

class UniversalImageBitmap extends Equatable {
  final int? height;
  final int? width;

  const UniversalImageBitmap({
    this.height,
    this.width,
  });

  @override
  List<Object?> get props => [height, width];
}
