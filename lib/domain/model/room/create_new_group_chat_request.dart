import 'package:equatable/equatable.dart';
import 'package:matrix/matrix.dart';

class CreateNewGroupChatRequest extends Equatable {
  final String? groupName;
  final List<String>? invite;
  final bool? enableEncryption;
  final CreateRoomPreset createRoomPreset;
  final String? urlAvatar;
  final Map<String, dynamic>? powerLevelContentOverride;

  const CreateNewGroupChatRequest({
    this.groupName,
    this.invite,
    this.enableEncryption,
    this.createRoomPreset = CreateRoomPreset.privateChat,
    this.urlAvatar,
    this.powerLevelContentOverride,
  });

  @override
  List<Object?> get props => [
        groupName,
        invite,
        enableEncryption,
        createRoomPreset,
        urlAvatar,
        powerLevelContentOverride,
      ];
}
