import 'package:equatable/equatable.dart';
import 'package:matrix/matrix.dart';

class NewRoomRequest extends Equatable {
  final String? groupName;
  final List<String>? invite;
  final bool? enableEncryption;
  final CreateRoomPreset createRoomPreset;
  final MatrixFile? avatar;

  const NewRoomRequest({
    this.groupName,
    this.invite,
    this.enableEncryption,
    this.createRoomPreset = CreateRoomPreset.privateChat,
    this.avatar,
  });
  
  @override
  List<Object?> get props => [
    groupName,
    invite,
    enableEncryption,
    createRoomPreset,
    avatar,
  ];
}