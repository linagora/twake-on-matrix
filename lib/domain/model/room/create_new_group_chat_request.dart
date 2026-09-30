import 'package:equatable/equatable.dart';
import 'package:matrix/matrix.dart';

class CreateNewGroupChatRequest extends Equatable {
  final String? groupName;
  final List<String>? invite;
  final bool? enableEncryption;
  final CreateRoomPreset createRoomPreset;
  final String? urlAvatar;
  final Map<String, dynamic>? powerLevelContentOverride;

  /// Public preset, listed in the room directory and never encrypted.
  final bool isPublic;

  /// Sets `m.federate: false` on a public room; cannot be changed later.
  final bool isServerLimited;

  const CreateNewGroupChatRequest({
    this.groupName,
    this.invite,
    this.enableEncryption,
    this.createRoomPreset = CreateRoomPreset.privateChat,
    this.urlAvatar,
    this.powerLevelContentOverride,
    this.isPublic = false,
    this.isServerLimited = false,
  });

  @override
  List<Object?> get props => [
    groupName,
    invite,
    enableEncryption,
    createRoomPreset,
    urlAvatar,
    powerLevelContentOverride,
    isPublic,
    isServerLimited,
  ];
}
