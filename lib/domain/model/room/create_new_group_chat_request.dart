import 'package:equatable/equatable.dart';
import 'package:matrix/matrix.dart';

class CreateNewGroupChatRequest extends Equatable {
  final String? groupName;
  final List<String>? invite;
  final bool? enableEncryption;
  final CreateRoomPreset createRoomPreset;
  final String? uriAvatar;

  const CreateNewGroupChatRequest({
    this.groupName,
    this.invite,
    this.enableEncryption,
    this.createRoomPreset = CreateRoomPreset.privateChat,
    this.uriAvatar,
  });

  @override
  List<Object?> get props => [
    groupName,
    invite,
    enableEncryption,
    createRoomPreset,
    uriAvatar,
  ];
}