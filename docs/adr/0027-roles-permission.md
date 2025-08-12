# 27. Define Permission Roles for Group Chat

### Context

- To manage access and actions within group chats, we need a clear definition of permission roles.
  Each role should have a specific set of permissions, ensuring proper access control and user
  experience.

### Decision

- We define four main roles: `Guest`, `Member`, `Moderator`, and `Admin`. Each role is associated
  with a set of permissions as follows:

## Guest - powerLevel = 0

- Can invite people to the room.
- Sample:

```dart
List<DefaultPermissionLevelMember> permissionForGuest(BuildContext context) {
  return [
    DefaultPermissionLevelMember.invitePeopleToTheRoom,
  ];
}
```

## Member - powerLevel = 10

- Can send messages.
- Can send reactions.
- Can delete messages sent by themselves.
- Can notify everyone using the room.
- Can join calls.

- Sample:

```dart
 List<DefaultPermissionLevelMember> permissionForMember(BuildContext context) {
  return [
    DefaultPermissionLevelMember.sendMessages,
    DefaultPermissionLevelMember.sendReactions,
    DefaultPermissionLevelMember.deleteMessagesSentByMe,
    DefaultPermissionLevelMember.notifyEveryoneUsingRoom,
    DefaultPermissionLevelMember.joinCall,
  ];
}
```

## Moderator - powerLevel = 50

- Can remove members.
- Can delete messages sent by others.
- Can pin messages for everyone.
- Can start calls.

- Sample:

```dart
List<DefaultPermissionLevelMember> permissionForModerator(BuildContext context,) {
  return [
    DefaultPermissionLevelMember.removeMembers,
    DefaultPermissionLevelMember.deleteMessagesSentByOthers,
    DefaultPermissionLevelMember.pinMessageForEveryone,
    DefaultPermissionLevelMember.startCall,
  ];
}
```

## Admin - powerLevel = 80

- Can change the group name.
- Can change the group description.
- Can change the group avatar.
- Can change group history visibility.
- Can assign roles

- Sample:

```dart
List<DefaultPermissionLevelMember> permissionForModerator(BuildContext context,) {
  return [
    DefaultPermissionLevelMember.changeGroupName,
    DefaultPermissionLevelMember.changeGroupDescription,
    DefaultPermissionLevelMember.changeGroupAvatar,
    DefaultPermissionLevelMember.changeGroupHistoryVisibility,
    DefaultPermissionLevelMember.assignRoles,
  ];
}
```